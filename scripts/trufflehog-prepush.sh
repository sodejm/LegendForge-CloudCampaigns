#!/usr/bin/env bash
set -euo pipefail

if ! command -v trufflehog >/dev/null 2>&1; then
  echo "trufflehog is required for secret scanning. Install trufflehog and retry." >&2
  exit 1
fi

if git rev-parse --is-inside-work-tree >/dev/null 2>&1 && [[ -f .git/index ]]; then
  trufflehog git file://. --no-update --results=verified,unknown --fail
else
  trufflehog filesystem --no-update --results=verified,unknown --fail .
fi
