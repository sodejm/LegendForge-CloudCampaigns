#!/usr/bin/env bash
set -euo pipefail

if ! command -v trufflehog >/dev/null 2>&1; then
  echo "trufflehog is required for secret scanning. Install trufflehog and retry." >&2
  exit 1
fi

if [[ "$#" -eq 0 ]]; then
  exit 0
fi

for target in "$@"; do
  if [[ -e "${target}" ]]; then
    trufflehog filesystem --no-update --results=verified,unknown --fail "${target}"
  fi
done
