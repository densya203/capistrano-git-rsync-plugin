# Changelog

All notable changes to this project will be documented in this file.

## [0.0.7] - 2026-03-31

### Changed
- Removed redundant `git reset --hard` after `git checkout -B`.
- Replaced `git rev-list --max-count=1` with `git rev-parse HEAD` for revision detection.
- Extracted repeated `fetch` calls into local variables for readability.
- Simplified `git fetch` + `git checkout -B` to `git fetch` + `git reset --hard FETCH_HEAD`.
- Cleaned up rsync options concatenation using splat expansion.
