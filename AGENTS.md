# Repository Guidance

## Agent compatibility

When changing agent-facing instructions or integrations, follow the applicable
specifications listed in the [AAIF project directory](https://aaif.io/projects).
Keep this file discoverable and scoped according to [AGENTS.md](https://agents.md/).
For changes to repository skills, verify the skill directory, frontmatter and
referenced files against the [Agent Skills specification](https://agentskills.io/specification).

## Layout and validation

- Terraform deployments live under `infrastructure/deployments/`; documentation is in root Markdown files, `docs/`, and `wiki/`.
- For multi-cloud Terraform changes, run `scripts/terraform-quality.sh` to cover all six deployments, including both low-cost configurations.
- Run applicable pre-commit and pre-push hooks for quality and security changes.

## Safety and workflow

- Never commit credentials, secret `.tfvars`, Terraform state, generated cloud data, or provider caches.
- Keep lockfile edits intentional and preserve required platform checksums.
- Treat live cloud provisioning, destructive changes, and paid services as external actions requiring explicit approval.
- Work on a dedicated branch or worktree; preserve unrelated changes and do not push unless explicitly requested.
- Before completion, check behavior, validation, documentation, dead code, and affected provider paths.

## Tracking work and capability gaps

- At task start, check the current checkout for a configured Squad team. When
  present, use its documented entry point and routing automatically for work
  within its scope and permissions. If the client cannot invoke Squad, report
  the limitation and follow any documented fallback.
- Commit each substantial, coherent increment after its relevant checks. At each
  checkpoint, update the linked issue with the commit SHA, checks run and their
  results, and remaining work. Apply the same practice to repository-local tickets.
- Update affected docs and examples in the same commit as the feature change.
  Limit capability claims to the versions, environments and behavior supported
  by evidence. Identify planned work, simulated results and unverified behavior.
- When evidence shows a promised capability is missing or a published claim is
  inaccurate, correct the claim and search for an existing bug. Update the match
  or file a bug in this repository when GitHub Issues is enabled. If Issues is
  disabled or the project has no remote, create a tracked Markdown ticket in the
  existing ticket directory, or `docs/issues/` if none exists. Record expected
  and observed behavior, affected revision, sanitized evidence and a verifiable
  closure condition. Use the project's private channel for sensitive evidence.
- When you repeat a check with stable inputs and an objective result, look for
  an existing command to reuse or extend. If none fits, add a small deterministic
  helper in the repository, exercise its success and failure paths, and document
  its invocation in the relevant skill or contributor guide. Use the helper on
  subsequent runs and retain human judgment for interpretive or approval steps.

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

## Milestone goal workflow

For an authorized request to work through a milestone or release, use the
[milestone-delivery skill](.agents/skills/milestone-delivery/SKILL.md). Start with
[prompts/next-milestone.md](prompts/next-milestone.md); see the
[usage guide](prompts/README.md) for scope, orchestration, model routing, and safe
storage. The main goal agent owns integration and verified delivery. These files
do not start a run or grant external-action authority by their presence alone.

## Required checkpoints, human review, and threat modeling

- Follow [Engineering review policy](docs/ENGINEERING_REVIEW.md). Create a local
  commit after each substantial coherent change and its relevant validation; do
  not defer all checkpoints until task completion. Use operational, imperative
  commit messages with actual validation and recovery details. Preserve unrelated
  work, existing checkpoints, signing requirements and stronger project gates.
- Update affected documentation in the same change. Require independent human
  review of the exact commit before merge/release; automated review is additional
  evidence. Record and schedule retroactive review of existing code in
  [Review coverage](docs/security/REVIEW_COVERAGE.md); do not mark pending code reviewed.
- Maintain the detailed [Threat model](docs/THREAT_MODEL.md) when code, dependencies,
  data flows, trust boundaries or deployment assumptions change. Record a specific
  no-impact rationale when unchanged. Reconcile at every release and quarterly.
  Keep source evidence, implemented/proposed controls, abuse cases, risk owners,
  validation and unresolved assumptions current. Human approval remains pending
  until an independent reviewer records it.
