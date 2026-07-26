#!/usr/bin/env bash
set -euo pipefail

# Verify public, unauthenticated reachability after a Terraform deployment.
#
# Usage:
#   scripts/post-deploy-smoke-test.sh [DEPLOYMENT_DIR]
#   FOUNDRY_URL=https://vtt.example.com scripts/post-deploy-smoke-test.sh
#
# FOUNDRY_URL takes precedence over Terraform discovery. Without it, the script
# reads only `terraform output -raw foundry_url` from DEPLOYMENT_DIR (default: .).

TIMEOUT="${TIMEOUT:-10}"
MAX_LATENCY_MS="${MAX_LATENCY_MS:-5000}"
PASS=0
FAIL=0
URL=""
SCHEME=""
HOST=""
HOST_IS_IP=0

usage() {
  printf 'Usage: %s [DEPLOYMENT_DIR]\n' "${0##*/}"
}

die() {
  printf 'Error: %s\n' "$1" >&2
  exit 2
}

pass() {
  printf '  [PASS] %s\n' "$1"
  PASS=$((PASS + 1))
}

fail() {
  printf '  [FAIL] %s\n' "$1"
  FAIL=$((FAIL + 1))
}

is_positive_decimal() {
  local value="$1"
  local nonzero_digits

  [[ "${value}" =~ ^[0-9]+([.][0-9]+)?$ ]] || return 1
  nonzero_digits="${value//./}"
  nonzero_digits="${nonzero_digits//0/}"
  [[ -n "${nonzero_digits}" ]]
}

validate_port() {
  local port="$1"

  [[ "${port}" =~ ^[0-9]+$ ]] || return 1
  [[ "${#port}" -le 5 ]] || return 1
  ((10#${port} >= 1 && 10#${port} <= 65535))
}

is_ipv4_literal() {
  local candidate="$1"
  local octets=()
  local octet

  [[ "${candidate}" =~ ^[0-9]+([.][0-9]+){3}$ ]] || return 1
  IFS='.' read -r -a octets <<<"${candidate}"
  [[ "${#octets[@]}" -eq 4 ]] || return 1
  for octet in "${octets[@]}"; do
    [[ "${#octet}" -le 3 ]] || return 1
    ((10#${octet} <= 255)) || return 1
  done
}

looks_like_ipv4_literal() {
  [[ "$1" =~ ^[0-9]+([.][0-9]+){3}$ ]]
}

is_ipv6_literal() {
  local candidate="$1"

  [[ "${candidate}" == *:* ]] || return 1
  [[ "${candidate}" =~ ^[0-9A-Fa-f:.]+$ ]]
}

is_dns_hostname() {
  local candidate="${1%.}"
  local labels=()
  local label

  [[ -n "${candidate}" && "${#candidate}" -le 253 ]] || return 1
  IFS='.' read -r -a labels <<<"${candidate}"
  for label in "${labels[@]}"; do
    [[ -n "${label}" && "${#label}" -le 63 ]] || return 1
    [[ "${label}" =~ ^[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?$ ]] || return 1
  done
}

validate_url() {
  local authority
  local port=""
  local remainder
  local suffix

  case "${URL}" in
    http://*)
      SCHEME="http"
      remainder="${URL#http://}"
      ;;
    https://*)
      SCHEME="https"
      remainder="${URL#https://}"
      ;;
    *)
      return 1
      ;;
  esac

  [[ -n "${remainder}" ]] || return 1
  [[ "${remainder}" != *[$' \t\r\n']* ]] || return 1
  authority="${remainder%%[/?#]*}"
  [[ -n "${authority}" && "${authority}" != *"@"* ]] || return 1

  if [[ "${authority}" == \[* ]]; then
    [[ "${authority}" == *"]"* ]] || return 1
    HOST="${authority#\[}"
    HOST="${HOST%%\]*}"
    suffix="${authority#*\]}"
    [[ -n "${HOST}" ]] || return 1
    if [[ -n "${suffix}" ]]; then
      [[ "${suffix}" == :* ]] || return 1
      port="${suffix#:}"
      validate_port "${port}" || return 1
    fi
    is_ipv6_literal "${HOST}" || return 1
    HOST_IS_IP=1
    return 0
  fi

  [[ "${authority}" != *:*:* ]] || return 1
  if [[ "${authority}" == *:* ]]; then
    HOST="${authority%%:*}"
    port="${authority#*:}"
    validate_port "${port}" || return 1
  else
    HOST="${authority}"
  fi

  if is_ipv4_literal "${HOST}"; then
    HOST_IS_IP=1
    return 0
  fi
  looks_like_ipv4_literal "${HOST}" && return 1
  is_dns_hostname "${HOST}" || return 1
  HOST_IS_IP=0
}

resolve_url() {
  local deployment_dir="${1:-.}"
  local discovered_url

  if [[ "${FOUNDRY_URL+x}" == "x" ]]; then
    printf '%s\n' "${FOUNDRY_URL}"
    return 0
  fi

  command -v terraform >/dev/null 2>&1 ||
    die "terraform is required to discover foundry_url; install it or set FOUNDRY_URL."

  if ! discovered_url="$(terraform -chdir="${deployment_dir}" output -raw foundry_url)"; then
    die "could not read foundry_url from Terraform deployment directory '${deployment_dir}'."
  fi
  [[ -n "${discovered_url}" ]] ||
    die "Terraform output foundry_url is empty in '${deployment_dir}'."
  printf '%s\n' "${discovered_url}"
}

check_dns() {
  local resolver_available=0

  if ((HOST_IS_IP)); then
    pass "Literal IP ${HOST} does not require DNS resolution"
    return
  fi

  if command -v getent >/dev/null 2>&1; then
    resolver_available=1
    if getent hosts "${HOST}" >/dev/null 2>&1; then
      pass "DNS resolves for ${HOST}"
      return
    fi
  fi
  if command -v host >/dev/null 2>&1; then
    resolver_available=1
    if host "${HOST}" >/dev/null 2>&1; then
      pass "DNS resolves for ${HOST}"
      return
    fi
  fi
  if command -v nslookup >/dev/null 2>&1; then
    resolver_available=1
    if nslookup "${HOST}" >/dev/null 2>&1; then
      pass "DNS resolves for ${HOST}"
      return
    fi
  fi

  if ((resolver_available)); then
    fail "DNS does not resolve for ${HOST}"
  else
    fail "No supported DNS resolver is available for ${HOST}"
  fi
}

latency_to_microseconds() {
  local value="$1"
  local seconds
  local fraction

  [[ "${value}" =~ ^[0-9]+([.][0-9]+)?$ ]] || return 1
  if [[ "${value}" == *.* ]]; then
    seconds="${value%%.*}"
    fraction="${value#*.}"
  else
    seconds="${value}"
    fraction="0"
  fi
  [[ "${#seconds}" -le 6 ]] || return 1
  fraction="${fraction}000000"
  fraction="${fraction:0:6}"
  printf '%d\n' "$((10#${seconds} * 1000000 + 10#${fraction}))"
}

check_http() {
  local curl_result
  local curl_status
  local http_status
  local latency_s
  local extra
  local latency_us
  local latency_ms
  local latency_limit_us

  if curl_result="$(
    curl --silent --show-error \
      --output /dev/null \
      --write-out '%{http_code} %{time_total}' \
      --connect-timeout "${TIMEOUT}" \
      --max-time "${TIMEOUT}" \
      "${URL}"
  )"; then
    curl_status=0
  else
    curl_status=$?
  fi

  if ((curl_status != 0)); then
    case "${curl_status}" in
      28)
        fail "Request timed out after ${TIMEOUT}s"
        ;;
      51 | 60)
        fail "TLS certificate validation failed"
        ;;
      *)
        fail "Request failed (curl exit ${curl_status})"
        ;;
    esac
    return
  fi

  read -r http_status latency_s extra <<<"${curl_result}"
  if [[ -n "${extra:-}" || ! "${http_status}" =~ ^[0-9]{3}$ ]]; then
    fail "curl returned malformed response metrics"
    return
  fi

  if [[ "${http_status}" =~ ^[23][0-9]{2}$ ]]; then
    pass "Service reachable (HTTP ${http_status})"
  else
    fail "Service returned unsuccessful HTTP ${http_status}"
  fi

  if [[ "${SCHEME}" == "https" ]]; then
    pass "HTTPS certificate validation passed"
  fi

  if ! latency_us="$(latency_to_microseconds "${latency_s}")"; then
    fail "curl returned invalid latency '${latency_s}'"
    return
  fi
  latency_limit_us=$((10#${MAX_LATENCY_MS} * 1000))
  latency_ms=$(((latency_us + 999) / 1000))
  if ((latency_us <= latency_limit_us)); then
    pass "Response latency ${latency_ms}ms is within ${MAX_LATENCY_MS}ms"
  else
    fail "Response latency ${latency_ms}ms exceeds ${MAX_LATENCY_MS}ms"
  fi
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi
[[ "$#" -le 1 ]] || {
  usage >&2
  exit 2
}

is_positive_decimal "${TIMEOUT}" ||
  die "TIMEOUT must be a positive number of seconds."
[[ "${MAX_LATENCY_MS}" =~ ^[0-9]+$ && "${#MAX_LATENCY_MS}" -le 9 ]] ||
  die "MAX_LATENCY_MS must be a non-negative integer."

URL="$(resolve_url "${1:-.}")"
validate_url || die "foundry_url must be a valid http:// or https:// URL with a valid hostname."
command -v curl >/dev/null 2>&1 ||
  die "curl is required for post-deployment smoke testing."

printf 'Checking post-deployment reachability: %s\n\n' "${URL}"
check_dns
check_http

printf '\nSmoke-test results: %d passed, %d failed\n' "${PASS}" "${FAIL}"
((FAIL == 0))
