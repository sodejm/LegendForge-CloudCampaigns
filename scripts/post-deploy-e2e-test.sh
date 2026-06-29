#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# LegendForge — Post-Deployment End-to-End Test
# -----------------------------------------------------------------------------
# Validates a live Foundry VTT deployment after `terraform apply`. The script is
# provider-agnostic: it discovers the deployment URL from Terraform outputs and
# runs a series of end-to-end smoke checks against the running service.
#
# Usage:
#   scripts/post-deploy-e2e-test.sh [DEPLOYMENT_DIR]
#   FOUNDRY_URL=https://vtt.example.com scripts/post-deploy-e2e-test.sh
#
#   DEPLOYMENT_DIR   Optional Terraform deployment directory to read the
#                    `foundry_url` output from. Defaults to the current dir or,
#                    if not a deployment, infrastructure/deployments/aws.
#
# Environment overrides:
#   FOUNDRY_URL      Skip Terraform discovery and test this URL directly.
#   TIMEOUT          Per-request timeout in seconds (default: 10).
#   MAX_LATENCY_MS   Fail the latency check above this threshold (default: 5000).
#
# Exit status: 0 if every check passes, non-zero if any check fails.
# =============================================================================

TIMEOUT="${TIMEOUT:-10}"
MAX_LATENCY_MS="${MAX_LATENCY_MS:-5000}"
PASS=0
FAIL=0

pass() { printf '  [PASS] %s\n' "$1"; PASS=$((PASS + 1)); }
fail() { printf '  [FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }

if ! command -v curl >/dev/null 2>&1; then
  echo "curl is required for end-to-end testing. Install curl and retry." >&2
  exit 1
fi

resolve_url() {
  if [[ -n "${FOUNDRY_URL:-}" ]]; then
    echo "${FOUNDRY_URL}"
    return 0
  fi

  if ! command -v terraform >/dev/null 2>&1; then
    echo "terraform is required to discover foundry_url. Install Terraform, or set FOUNDRY_URL." >&2
    exit 1
  fi

  local dir="${1:-}"
  if [[ -z "${dir}" ]]; then
    if [[ -f terraform.tf || -f main.tf ]]; then
      dir="."
    else
      dir="infrastructure/deployments/aws"
    fi
  fi

  terraform -chdir="${dir}" output -raw foundry_url 2>/dev/null
}

URL="$(resolve_url "${1:-}")"
if [[ -z "${URL}" ]]; then
  echo "Could not determine deployment URL. Set FOUNDRY_URL or run terraform apply first." >&2
  exit 1
fi

HOST="${URL#*://}"
HOST="${HOST%%/*}"
HOST="${HOST%%:*}"

echo "Running post-deployment end-to-end tests against: ${URL}"
echo

# DNS resolution
if getent hosts "${HOST}" >/dev/null 2>&1 || host "${HOST}" >/dev/null 2>&1; then
  pass "DNS resolves for ${HOST}"
else
  fail "DNS does not resolve for ${HOST}"
fi

# Reachability and HTTP status
status="$(curl -sS -o /dev/null -w '%{http_code}' --max-time "${TIMEOUT}" "${URL}" 2>/dev/null || true)"
if [[ "${status}" =~ ^(200|301|302|307|308|401|403)$ ]]; then
  pass "Service reachable (HTTP ${status})"
else
  fail "Service unreachable or unexpected status (HTTP ${status})"
fi

# Foundry setup/launch endpoint
setup_status="$(curl -sS -o /dev/null -w '%{http_code}' --max-time "${TIMEOUT}" "${URL%/}/setup" 2>/dev/null || true)"
if [[ "${setup_status}" =~ ^(200|301|302|307|308|401|403)$ ]]; then
  pass "Foundry /setup endpoint responding (HTTP ${setup_status})"
else
  fail "Foundry /setup endpoint not responding (HTTP ${setup_status})"
fi

# TLS certificate validity (HTTPS only)
if [[ "${URL}" == https://* ]]; then
  if curl -sS -o /dev/null --max-time "${TIMEOUT}" "${URL}" 2>/dev/null; then
    pass "TLS certificate valid"
  else
    fail "TLS certificate invalid or HTTPS handshake failed"
  fi
fi

# Latency budget
latency_s="$(curl -sS -o /dev/null -w '%{time_total}' --max-time "${TIMEOUT}" "${URL}" 2>/dev/null || true)"
latency_ms="$(awk -v t="${latency_s}" 'BEGIN { printf "%d", t * 1000 }')"
if [[ "${latency_ms}" -gt 0 && "${latency_ms}" -le "${MAX_LATENCY_MS}" ]]; then
  pass "Response latency ${latency_ms}ms within ${MAX_LATENCY_MS}ms budget"
else
  fail "Response latency ${latency_ms}ms exceeds ${MAX_LATENCY_MS}ms budget"
fi

echo
echo "End-to-end results: ${PASS} passed, ${FAIL} failed"
if [[ "${FAIL}" -gt 0 ]]; then
  exit 1
fi
