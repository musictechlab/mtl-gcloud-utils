#!/usr/bin/env bash
# cleanup.sh
# Deletes a list of GCP projects and CONTINUES on errors.
# - Logs successes to deleted_projects.txt
# - Logs failures  to failed_projects.txt
# - Supports DRY_RUN=1 to only print intended actions
# - Retries transient failures up to $RETRIES with exponential backoff

set -u               # no unset vars
set -o pipefail      # fail on pipe errors
# NOTE: DO NOT 'set -e' — we want to continue on failures

# ====== CONFIG ======
REGION=${REGION:-europe-central2}
DRY_RUN=${DRY_RUN:-0}          # set to 1 for dry run
RETRIES=${RETRIES:-3}
BACKOFF_BASE=${BACKOFF_BASE:-2}

DELETED_LOG="deleted_projects.txt"
FAILED_LOG="failed_projects.txt"

# Clear logs
: > "${DELETED_LOG}"
: > "${FAILED_LOG}"

echo "🚨 Deleting old GCP projects... (continue on error)"
echo "Active gcloud account: $(gcloud config get-value account 2>/dev/null)"
echo "Using region: ${REGION} | DRY_RUN=${DRY_RUN} | RETRIES=${RETRIES} | BACKOFF_BASE=${BACKOFF_BASE}"

delete_project() {
  local pid="$1"
  local attempt=1

  if [[ "${DRY_RUN}" == "1" ]]; then
    echo "DRY_RUN: would delete project: ${pid}"
    return 0
  fi

  while (( attempt <= RETRIES )); do
    # Try delete and capture output
    output="$(gcloud projects delete "${pid}" --quiet 2>&1)"
    rc=$?
    if [[ $rc -eq 0 ]]; then
      echo "✅ Deleted: ${pid}"
      echo "${pid}" >> "${DELETED_LOG}"
      return 0
    fi

    # Non-retriable errors
    if echo "${output}" | grep -qiE "PERMISSION_DENIED|NOT_FOUND|The caller does not have permission"; then
      echo "⛔ Skipping (no access or not found): ${pid}"
      printf "%s | %s\n" "${pid}" "${output}" >> "${FAILED_LOG}"
      return 1
    fi

    # Backoff & retry
    sleep_s=$(( BACKOFF_BASE ** (attempt - 1) ))
    echo "⚠️  Delete failed for ${pid} (attempt ${attempt}/${RETRIES}). Retrying in ${sleep_s}s..."
    sleep "${sleep_s}"
    (( attempt++ ))
  done

  echo "❌ Failed after ${RETRIES} attempts: ${pid}"
  echo "${pid}" >> "${FAILED_LOG}"
  return 1
}

# ====== LIST OF PROJECT IDS TO DELETE ======
projects=(
  example-project-123
  example-project-456
  example-project-789
)

# ====== EXECUTION ======
overall_rc=0
for pid in "${projects[@]}"; do
  echo "---- Deleting: ${pid} ----"
  if ! delete_project "${pid}"; then
    overall_rc=1
  fi
done

echo "🏁 Done. See logs:"
echo "  - ${DELETED_LOG} (deleted)"
echo "  - ${FAILED_LOG}  (failed/skipped)"
exit "${overall_rc}"

