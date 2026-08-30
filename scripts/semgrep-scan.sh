#!/usr/bin/env bash
set -euo pipefail

if ! command -v semgrep >/dev/null 2>&1; then
  echo "semgrep is required for static analysis. Install semgrep and retry." >&2
  exit 1
fi

# Strict mode turns internal matching warnings into failures, so an incomplete
# local or CI scan cannot look clean. These three rules require the authenticated
# Pro engine and are instead covered by the dedicated Semgrep workflow and its
# SARIF upload. New incompatible rules fail this gate until handled explicitly.
semgrep --strict --config p/ci --error --metrics=off --exclude .terraform --exclude .git \
  --exclude-rule=javascript.crypto-js.cryptojs-weak-algorithm.cryptojs-weak-algorithm \
  --exclude-rule=javascript.express.web.cors-default-config-express.cors-default-config-express \
  --exclude-rule=javascript.koa.web.cors-default-config-koa.cors-default-config-koa \
  .
