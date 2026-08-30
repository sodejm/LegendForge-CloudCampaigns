#!/usr/bin/env bash
set -euo pipefail

if ! command -v semgrep >/dev/null 2>&1; then
  echo "semgrep is required for static analysis. Install semgrep and retry." >&2
  exit 1
fi

# The p/ci ruleset contains rules that require the Pro engine.  Strict mode turns
# internal matching warnings into failures so a partial scan cannot look clean.
semgrep --pro --strict --config p/ci --error --metrics=off --exclude .terraform --exclude .git .
