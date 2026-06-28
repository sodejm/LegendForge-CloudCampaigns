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

terraform fmt -check -recursive "${ROOT_DIR}"

for deployment_dir in "${ROOT_DIR}"/infrastructure/deployments/*; do
  [[ -d "${deployment_dir}" ]] || continue
  echo "Running Terraform validate + TFLint in ${deployment_dir}"
  terraform -chdir="${deployment_dir}" init -backend=false -input=false -no-color >/dev/null
  terraform -chdir="${deployment_dir}" validate -no-color
  tflint --chdir="${deployment_dir}" --init
  tflint --chdir="${deployment_dir}"
done
