#!/usr/bin/env bash
set -euo pipefail

if ! command -v terraform >/dev/null 2>&1; then
  echo "terraform is required for formatting checks. Install Terraform and retry." >&2
  exit 1
fi

terraform fmt -check -recursive .
