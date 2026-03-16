# cleanup.sh — Delete multiple GCP projects (and keep going)

This script deletes a list of Google Cloud projects and **continues on errors**.  
It retries transient failures with exponential backoff and logs results to files.

## What it does

- Iterates over a hardcoded `projects=(...)` list
- Runs `gcloud projects delete <PROJECT_ID> --quiet`
- Retries up to `$RETRIES` times with backoff `$BACKOFF_BASE`
- Skips non-retriable errors (e.g., **PERMISSION_DENIED**, **NOT_FOUND**)
- Writes:
  - `deleted_projects.txt` — successfully deleted project IDs
  - `failed_projects.txt` — failed/skipped IDs with error messages

## Prerequisites

- Google Cloud SDK (`gcloud`) installed and authenticated:
  ```bash
  gcloud auth login
  gcloud auth list
  ```

## License

MIT License — see [LICENSE](LICENSE) for details.

---

<div align="center">
  MusicTech Lab - Rockstars Developers dedicated to the Music Industry<br>
  <a href="https://musictechlab.io">Website</a>
  <span> | </span>
  <a href="https://linkedin.com/company/musictechlab">LinkedIn</a>
  <span> | </span>
  <a href="https://musictechlab.io/contact">Let's talk</a><br>
  Crafted by <a href="https://musictechlab.io">musictechlab.io</a>
</div>
