# Repository Guidance

## Layout and validation

- Terraform deployments live under `infrastructure/deployments/`; documentation is in root Markdown files, `docs/`, and `wiki/`.
- For multi-cloud Terraform changes, run `TERRAFORM_QUALITY_TARGETS=aws,azure,gcp,hetzner scripts/terraform-quality.sh`.
- Run applicable pre-commit and pre-push hooks for quality and security changes.

## Safety and workflow

- Never commit credentials, secret `.tfvars`, Terraform state, generated cloud data, or provider caches.
- Keep lockfile edits intentional and preserve required platform checksums.
- Treat live cloud provisioning, destructive changes, and paid services as external actions requiring explicit approval.
- Work on a dedicated branch or worktree; preserve unrelated changes and do not push unless explicitly requested.
- Before completion, check behavior, validation, documentation, dead code, and affected provider paths.
