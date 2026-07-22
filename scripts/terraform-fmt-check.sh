#!/usr/bin/env bash
set -euo pipefail

if ! command -v terraform >/dev/null 2>&1; then
  echo "terraform is required for formatting checks. Install Terraform and retry." >&2
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_DEPLOYMENTS="${TERRAFORM_QUALITY_TARGETS:-aws}"

if [[ "$#" -gt 0 ]]; then
  for target in "$@"; do
    [[ "${target}" == *.tf ]] || continue
    terraform fmt -check "${target}"
  done

  exit 0
fi

IFS=',' read -r -a deployment_names <<< "${TARGET_DEPLOYMENTS}"

for deployment_name in "${deployment_names[@]}"; do
  deployment_name="${deployment_name//[[:space:]]/}"
  [[ -n "${deployment_name}" ]] || continue
  deployment_dir="${ROOT_DIR}/infrastructure/deployments/${deployment_name}"
  [[ -d "${deployment_dir}" ]] || continue

  terraform fmt -check -recursive "${deployment_dir}"
done

shopt -s nullglob
for module_dir in "${ROOT_DIR}/infrastructure/modules"/*/; do
  terraform fmt -check -recursive "${module_dir}"
done
