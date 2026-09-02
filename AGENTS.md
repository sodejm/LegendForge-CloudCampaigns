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

## Meaningful change standard

Do not make churn-only edits.

Avoid changing synonyms, wording, comments, variable names, formatting, or code
structure unless the change materially improves correctness, safety, performance,
accessibility, maintainability, clarity of domain meaning or behavior, consistency
with an established project convention, testability, observability, operational
support, or compliance with an explicit requirement, issue, review comment, or
style rule.

Before renaming a variable, function, type, file, or public API, verify that the
new name resolves a real ambiguity, incorrect implication, collision, or
domain-model mismatch. Do not rename merely because another synonym may sound
preferable.

Preserve stable terminology used by public APIs, schemas, documentation,
configuration, tests, logs, and integrations unless a coordinated migration is
explicitly required.

For proposed wording-only or naming-only changes, state the concrete ambiguity or
misunderstanding being removed. If none can be identified, leave the existing
wording unchanged.

Prefer focused diffs. Do not bundle cleanup, rewording, or stylistic normalization
into behavior-changing work unless explicitly requested.
