#!/usr/bin/env bash
set -euo pipefail

if ! command -v terraform >/dev/null 2>&1; then
  echo "terraform is required for validate checks. Install Terraform and retry." >&2
  exit 1
fi

if ! command -v tflint >/dev/null 2>&1; then
  echo "tflint is required for lint checks. Install tflint and retry." >&2
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_DEPLOYMENTS="${TERRAFORM_QUALITY_TARGETS:-aws}"

IFS=',' read -r -a deployment_names <<< "${TARGET_DEPLOYMENTS}"

for deployment_name in "${deployment_names[@]}"; do
  deployment_dir="${ROOT_DIR}/infrastructure/deployments/${deployment_name}"
  [[ -d "${deployment_dir}" ]] || continue
  echo "Running Terraform validate + TFLint in ${deployment_dir}"
  terraform -chdir="${deployment_dir}" init -backend=false -input=false -no-color >/dev/null
  terraform -chdir="${deployment_dir}" validate -no-color
  if [[ -f "${deployment_dir}/.tflint.hcl" ]]; then
    tflint --chdir="${deployment_dir}" --init
  fi
  tflint --chdir="${deployment_dir}"
done
