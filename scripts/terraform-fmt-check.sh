#!/usr/bin/env bash
set -euo pipefail

if ! command -v terraform >/dev/null 2>&1; then
  echo "terraform is required for formatting checks. Install Terraform and retry." >&2
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_DEPLOYMENTS="${TERRAFORM_QUALITY_TARGETS:-aws}"

if [[ "$#" -gt 0 ]]; then
  found_tf=false
  for target in "$@"; do
    [[ "${target}" == *.tf ]] || continue
    found_tf=true
    terraform fmt -check "${target}"
  done

  if [[ "${found_tf}" == false ]]; then
    exit 0
  fi

  exit 0
fi

IFS=',' read -r -a deployment_names <<< "${TARGET_DEPLOYMENTS}"

for deployment_name in "${deployment_names[@]}"; do
  deployment_dir="${ROOT_DIR}/infrastructure/deployments/${deployment_name}"
  [[ -d "${deployment_dir}" ]] || continue

  terraform fmt -check -recursive "${deployment_dir}"
  terraform fmt -check -recursive "${ROOT_DIR}/infrastructure/modules/aws-asg-ec2"
  terraform fmt -check -recursive "${ROOT_DIR}/infrastructure/modules/aws-alb"
  terraform fmt -check -recursive "${ROOT_DIR}/infrastructure/modules/aws-cloudfront"
  terraform fmt -check -recursive "${ROOT_DIR}/infrastructure/modules/aws-cloudwatch"
  terraform fmt -check -recursive "${ROOT_DIR}/infrastructure/modules/aws-iam"
  terraform fmt -check -recursive "${ROOT_DIR}/infrastructure/modules/aws-rds"
  terraform fmt -check -recursive "${ROOT_DIR}/infrastructure/modules/aws-route53"
  terraform fmt -check -recursive "${ROOT_DIR}/infrastructure/modules/aws-s3"
  terraform fmt -check -recursive "${ROOT_DIR}/infrastructure/modules/aws-security-groups"
  terraform fmt -check -recursive "${ROOT_DIR}/infrastructure/modules/aws-vpc"
done
