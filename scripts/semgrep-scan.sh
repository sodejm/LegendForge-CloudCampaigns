#!/usr/bin/env bash
set -euo pipefail

if ! command -v semgrep >/dev/null 2>&1; then
  echo "semgrep is required for static analysis. Install semgrep and retry." >&2
  exit 1
fi

semgrep --config p/ci --error --metrics=off --exclude .terraform --exclude .git .
