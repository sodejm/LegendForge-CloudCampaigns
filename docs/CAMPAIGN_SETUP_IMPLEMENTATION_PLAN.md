# End-to-end campaign setup implementation plan

Status: approved implementation sequence for [issue #106](https://github.com/sodejm/LegendForge-CloudCampaigns/issues/106)

This document turns the campaign-setup workstream into reviewable delivery
increments. It is a plan, not a statement that the integrations or deployment
profiles are complete. In particular, premium installation and billable cloud
provisioning remain disabled until their milestone gates have evidence.

## Release outcome and boundaries

The first release must take one campaign through this operator-visible flow:

```text
Select game -> save credentials -> verify entitlement and compatibility
            -> review deployment -> provision -> install -> create world
            -> launch as GM
```

The release is gated on all six profiles: AWS low cost, GCP low cost, AWS
standard, GCP standard, Azure standard, and Hetzner. Providers are implemented
sequentially behind common interfaces; provider-specific behavior must not fork
the launcher into separate applications.

The launcher owns catalog access, credential references, requirements,
workflow state, and installation. Terraform owns infrastructure resources and
receives only nonsecret configuration and opaque secret references. Live cloud
operations, paid services, destructive actions, and use of real consumer
accounts require a separately authorized qualification run.

The initial release excludes native Windows support, multiple worlds per
campaign server, additional recipes beyond the qualified initial set,
migration, and active/passive failover.

## Architectural decision

Use a Python package with bundled local browser assets. The package exposes the
following interfaces; integrations depend on these contracts rather than on
one another's concrete implementations.

| Interface | Contract |
| --- | --- |
| `CatalogAdapter` | Search listings, traverse pagination, retry bounded transient failures, validate responses, cache safe metadata, and map listings to Foundry package IDs. |
| `EntitlementVerifier` | Return an entitlement result without conflating consumer content ownership with Foundry license validity. |
| `CredentialStore` | Save, resolve, replace, and delete an opaque reference using an explicitly allowed OS keyring backend. |
| `RequirementsResolver` | Resolve pinned releases, manifest dependencies, compatibility, and resource requirements. |
| `DeploymentPlan` | Represent nonsecret campaign choices, pinned versions, proposed resources, cost information, and preflight results; produce a stable digest. |
| `ProviderAdapter` | Translate an approved plan into infrastructure operations, runtime secret delivery, checkpoints, and recovery instructions. |
| `InstallationCoordinator` | Resume package installation, world creation, supported content import, and launch verification without duplicating completed work. |

### Planned package and test layout

The first code-bearing increment will introduce this structure without putting
provider credentials or captured account data in the repository:

```text
src/legendforge/
  catalog/          # protocol, validated models, cache, storefront adapters
  entitlements/     # result contract and verifier implementations
  credentials/      # secret wrapper, opaque references, keyring allowlist
  requirements/     # release manifests, dependency and compatibility resolver
  planning/         # immutable deployment plan and approval digest
  providers/        # shared protocol and six provider adapters
  installation/     # resumable, idempotent stage coordination
  journal/          # versioned nonsecret run journal
  web/              # loopback service and bundled browser assets
recipes/            # reviewed, versioned game recipes
tests/
  fixtures/catalog/ # synthetic or sanitized responses and provenance notes
  unit/
  contract/
  integration/
```

Package boundaries are intentionally narrower than a general workflow
framework. A single-process launcher plus explicit stage records is the simpler
alternative. It avoids a durable queue and distributed control plane until
measured reliability or concurrency requirements justify them.

### Architecture assessment

| Dimension | Decision and trade-off |
| --- | --- |
| Security | Secrets are stored locally through an allowlisted OS backend and resolved only at the last responsible launcher/runtime boundary. Terraform state, cloud-init, command arguments, logs, fixtures, journals, plans, and browser URLs must never contain secret values. This is safer than marking Terraform values `sensitive`, which only redacts selected display paths. |
| Cost | Local orchestration has no always-on control-plane cost. Provider-native secret stores can add small storage or API costs, which the review plan must show. No integration test may create paid resources by default. |
| Performance | Catalog metadata is cached with evidence timestamps and bounded freshness. Installation is stage-based because cloud and package latency dominates local orchestration; timings will be captured during qualification rather than guessed. |
| Maintainability | Typed shared contracts and contract tests prevent six provider-specific wizards. The cost is adapter/versioning discipline. Versioned journals and recipes provide explicit migration points. |

Rollback is incremental: each milestone remains behind an unavailable/disabled
capability until its evidence is accepted. Existing manual Terraform deployment
entry points remain usable while the launcher is introduced.

## Shared data contracts

### Catalog records

A normalized catalog record contains:

- adapter and schema versions;
- storefront listing ID and canonical URL;
- publisher and title;
- `system`, `module`, or other package kind;
- zero or more verified Foundry package IDs;
- `release_state`: `released` or `preorder`;
- `is_enhancement`: boolean classification independent of release state;
- release/manifest metadata when supplied by an authoritative package source;
- observation time and cache expiry; and
- source evidence identifiers that contain no credentials or customer data.

Unknown fields are tolerated only at the transport boundary. Required fields,
types, enumerations, and pagination links are validated before normalization.
A schema failure returns a typed adapter error and does not silently omit a
listing. Missing or unrecognized release states fail validation. Recipes define
whether a package is required or optional independently of its release state and
enhancement classification. Preorders may be displayed but never selected for
installation, including optional enhancements that are also preorders.

### Entitlement results

The stable result contract is:

```text
schema_version: entitlement result schema version
status: owned | not_owned | unknown | not_required
subject: content package or Foundry license identifier
provider: ownership authority identifier
verifier: verifier identifier and implementation version
policy_version: reviewed verification and freshness policy version
principal_ref: opaque nonsecret reference to the verified consumer account
credential_ref: opaque reference to the credential used for the check
credential_generation: credential revision, advanced on replacement
evidence_source: verifier-defined nonsecret source label
checked_at: UTC timestamp
valid_until: UTC timestamp or null
reason_code: stable machine-readable reason
```

`owned` means an authorized consumer-facing check produced current affirmative
evidence. `not_owned` means an authoritative check produced a current negative
result. `unknown` covers unavailable APIs, stale evidence, malformed responses,
authentication failure, rate limiting after bounded retries, and paths for
which no authorized consumer check exists. `not_required` is valid only for a
recipe item explicitly marked as not requiring ownership.

Evidence and its cache key are scoped to the schema, subject, provider, verifier,
policy version, principal reference, credential reference, and credential
generation. References must not expose account IDs, emails, credentials, or
hashes of secret values. The verifier must establish the consumer principal;
an unresolved principal cannot authorize `owned`. Identity fields may be null
for an unauthenticated `unknown` result, but that result cannot authorize
installation. `not_required` may omit principal and credential identity only
for the explicit recipe path that requires no ownership check.

Account switching, credential replacement, and credential deletion invalidate
associated evidence, including evidence loaded from a resumed journal.
Replacement advances the credential generation even when its opaque reference
is retained. Review, apply, and resume compare the evidence identity against the
current credential-store identity and generation before accepting a cached
result. A changed identity requires a new check; evidence for one account cannot
authorize another account's installation.

Protected content proceeds only with a fresh `owned` result. `unknown` and
expired results fail closed. Review and apply both reevaluate freshness; a
material result change invalidates plan approval. Foundry license validation is
a distinct subject and never supplies content-ownership evidence.

Default freshness values will not be invented in code. Each verifier must
declare a reviewed maximum age based on its source semantics, and the recipe
records whether an apply-time online recheck is mandatory.

### Run journal and approval

The journal is versioned, nonsecret, append-oriented, and written atomically. It
contains campaign ID, plan digest, provider resource references, stage inputs by
digest, stage outcomes, timestamps, success evidence, retry classification, and
recovery checkpoints. It rejects credential material and secret wrapper values
during serialization.

Approval binds to a versioned, canonically serialized projection of the
nonsecret `DeploymentPlan`. The projection includes selected content and recipe
versions, pinned releases, profile, region, hostname, storage, resource actions,
cost amounts and assumptions, credential references and generations, unresolved
requirements, and material preflight outcomes. Entitlement outcomes include
status, subject, provider, verifier/schema/policy versions, principal and
credential identity, evidence source, and reason code. Changes to any of these
fields change the digest and clear approval. New material plan fields require
an explicit projection/schema update rather than being silently excluded.

Observation and freshness metadata, including `checked_at`, `valid_until`, cache
expiry, and check execution timestamps, remain in the full plan and journal but
are excluded from the approval projection. Refreshing those values alone keeps
the approved digest only when the material outcomes and identities are
unchanged. Digest equality never substitutes for a successful preflight check:
apply and resume still validate current identity, enforce freshness policies,
and perform required online rechecks before proceeding. Expired, failed,
unknown, or missing required evidence blocks execution even with a matching
digest. Material changes require renewed review and acknowledgement.

## Milestone gates

### Milestone 1 — executable integration proofs (#107–#110)

#### #107 Catalog discovery

1. Record endpoint provenance, authorization assumptions, pagination behavior,
   observed response version, and sanitization steps next to each fixture.
2. Add synthetic fixtures for malformed data and sanitized fixtures only when
   their terms permit repository storage. Replace account IDs, emails, tokens,
   order IDs, and request correlation values; scan both raw staging paths and
   committed fixtures before publication.
3. Implement the adapter protocol, validated normalized model, bounded
   exponential backoff with jitter, pagination cycle protection, and a cache
   keyed by adapter/schema/query version.
4. Maintain reviewed mapping data separately from transport fixtures. Initial
   recipes cover Cosmere and D&D system-only paths plus only premium items whose
   package IDs and supported install paths are verified.
5. Test publisher add-ons that a system-only query would miss, independent
   release/enhancement/recipe-optionality classifications, rejection of optional
   preorders and missing/unknown release states, duplicate listings, stale cache
   behavior, pagination, rate limiting, and additive/breaking schema changes.

Acceptance evidence: deterministic fixture-backed contract tests, fixture
provenance/sanitization notes, and a mapping review identifying every unresolved
package ID. A storefront description alone is not compatibility evidence.

#### #108 Entitlement investigation

1. Inventory every premium content path named by an initial recipe.
2. For each path, document whether an authorized consumer ownership endpoint or
   supported local receipt exists, its authorization model, evidence semantics,
   freshness rule, and terms/permission basis.
3. Implement the result model and a fake verifier first. Add a real verifier
   only after the consumer authorization path is demonstrated with an approved
   test entitlement outside recorded fixtures and logs.
4. Test all four statuses, expired evidence, authentication failure, throttling,
   malformed responses, content/license separation, and apply-time rechecks.
   Verify that cross-account cache reuse, credential replacement under the same
   reference, deletion, and resume with a changed principal or generation cannot
   reuse affirmative evidence. An unresolved principal must never yield `owned`.
5. Mark paths without an authorized ownership check `unknown` and list the
   precise upstream capability or permission needed to unblock them.

Acceptance evidence: contract tests and a capability-matrix row per premium
path. Publisher-facing catalog access is not accepted as proof of consumer
ownership.

#### #109 Installation and world setup proof

Start only after package IDs and compatibility sources are verified. Pin
Foundry core/image, system, module, and content versions. Prove system-only world
creation before premium import. Every step must document whether it uses a
supported Foundry/package interface, its idempotency key, observable success,
retry class, and recovery action. Premium tests additionally depend on increment
C (#108) producing fresh affirmative consumer ownership evidence bound to the
same principal and credential generation used for installation. They use
separately authorized test entitlements and never commit exported content.
An entitlement blocker is not a qualified premium path; system-only proof can
proceed while that premium path remains blocked.

#### #110 Runtime secret-delivery proof

Before altering deployment roots, implement a synthetic-secret leakage harness
that scans Terraform inputs/state/show output, rendered bootstrap data, process
arguments, logs, journals, and persisted launcher data. Prove retrieval after
service restart and compute replacement.

| Profile | Candidate delivery design to prove | Required identity/recovery evidence |
| --- | --- | --- |
| AWS low cost and standard | AWS Secrets Manager or SSM Parameter Store; instance role retrieves at runtime into a root-owned runtime file or credential mechanism. | Least-privilege resource policy, no user-data value, restart retrieval, replacement retrieval, and revoked-reference failure. |
| GCP low cost and standard | Secret Manager; attached service account retrieves at runtime into a root-owned runtime file or credential mechanism. | Least-privilege IAM, no metadata startup-script value, restart/replacement retrieval, and disabled-version failure. |
| Azure standard | Key Vault; managed identity retrieves at runtime into a root-owned runtime file or credential mechanism. | Least-privilege RBAC/access policy, no custom-data value, VMSS replacement retrieval, and disabled-secret failure. |
| Hetzner | No provider-native workload identity is assumed. Compare a one-time authenticated bootstrap exchange with an operator-controlled secret service or encrypted host-bound envelope. | Threat model, authenticated first retrieval, replay/expiry handling, rotation, restart without launcher availability where required, replacement enrollment, and revocation. |

The Hetzner choice remains an explicit #110 blocker until its threat model and
restart/replacement proof are reviewed. Terraform receives a reference or
resource identity, never the value. Passing references through Terraform is
acceptable only after verifying the reference itself grants no secret access.

Milestone 1 exits with a versioned capability matrix containing `supported`,
`blocked`, or `unsupported` for each catalog, entitlement, installation, and
secret-delivery path, linked to executable evidence.

### Milestone 2 — local wizard and credential lifecycle (#111–#114)

- Detect browser executable, version, and default independently from launching.
  Prefer an eligible default, allow an explicit executable, and always expose a
  copyable loopback URL.
- Bind only to loopback on a random port. Keep pairing material out of URLs;
  validate Host and Origin, require same-origin POSTs, validate request schemas,
  apply restrictive security headers, and require handshake plus acknowledgement.
- Test cancellation, expiry, stale and duplicate submissions. Browser launch,
  browser exit, or an unacknowledged POST cannot authorize deployment.
- Treat wizard communication and Foundry rendering capability as separate
  checks.
- Provide pasteable masked fields with accessible show/hide controls and
  password-manager metadata. Allow only reviewed Keychain, Secret Service, or
  KWallet `keyring` backends. Reject fallback/unknown backends.
- Return opaque saved references, clear submitted fields, and never expose
  stored-value readback. Support scoped reuse, replacement, and deletion while
  explaining that deletion does not revoke upstream credentials.
- Wrap resolved values in a type that rejects string formatting, representation,
  logging, equality diagnostics, and serialization. Do not claim Python or
  browser strings can be reliably erased from memory.

### Milestone 3 — recipes and reviewable plans (#115–#118)

Recipes identify required and optional packages, compatible released versions,
manifest dependencies, world creation/import operations, entitlement rules,
resources, and qualification evidence. The resolver uses release manifests and
dependency metadata rather than storefront copy.

Review shows the game/content, profile, region, hostname, retained storage,
pinned Foundry image/core/package versions, ownership/compatibility, resource
create/reuse actions, cost facts with source time, unresolved requirements, and
credential references without values. Apply requires an acknowledged current
digest and reruns time-sensitive entitlement and infrastructure checks.

### Milestone 4 — provisioning and resumable installation (#119–#126)

All adapters implement this shared stage sequence:

```text
Preflight -> Review -> Provision -> Configure HTTPS -> Deliver secrets
          -> Install packages -> Create world -> Import content -> Verify launch
```

Every stage declares input digests, success evidence, safe retries, terminal
failures, and operator recovery. Resource identities are journaled immediately.
Reconciliation must not overwrite unrelated DNS or create duplicates. Each
profile must enforce one active campaign server and one authoritative persistent
data writer during replacement.

Implementation order is AWS low cost, GCP low cost, AWS/GCP standard, then Azure
and Hetzner. Completion still requires all six profiles.

### Milestone 5 — playable-world qualification (#127–#130)

Create a unique campaign world, enable required modules, execute only qualified
imports, checkpoint import completion to prevent duplication, configure GM
access securely, and verify world launch plus representative asset loading. An
HTTPS health response is intermediate evidence, not playable-world completion.

## Validation and evidence matrix

| Gate | Automated evidence | Authorized/manual evidence |
| --- | --- | --- |
| Browser | macOS/Linux discovery fixtures; valid round trips; invalid origin/host/schema; stale, duplicate, expiry, cancellation; security headers. | Supported installed browsers render the wizard and a qualified Foundry client. |
| Credentials | Fake approved/denied backends; paste/reveal UI; reference lifecycle; locked store; no readback; serialization/log redaction. | Keychain, Secret Service, and KWallet qualification on their native OS/session. |
| Catalog/preflight | Schema mutations, pagination cycles, stale cache, optional preorders, add-ons, incompatible releases, missing/unknown ownership, identity-scoped entitlement cache and resume. | Endpoint permission and sanitized-fixture review. |
| Approval | Timestamp-only successful refresh preserves the digest; material outcome/identity changes clear approval; expired or failed required rechecks block apply/resume despite a matching digest. | Review of the versioned material-field projection and freshness policies. |
| Infrastructure | Offline Terraform tests for six profiles; synthetic leakage scan; replacement and writer-invariant state-machine tests. | Authorized provider plans and sandbox deployments; DNS/HTTPS reconciliation. |
| Recovery | Fault injection after every stage; restart/resume; stable resource/world/import idempotency keys. | Authorized server replacement and retained-storage recovery. |
| Playability | Recipe/schema and mocked launch-verification tests. | Cosmere and D&D system-only worlds, then each qualified premium recipe, GM login, and asset loading. |

Repository-level checks for implementation increments include targeted Python
tests, the applicable pre-commit/pre-push hooks, documentation/wiki validation,
secret scanning, and:

```bash
TERRAFORM_QUALITY_TARGETS=aws,azure,gcp,hetzner,aws-low-cost,gcp-low-cost \
  scripts/terraform-quality.sh
```

The Terraform matrix is required only when Terraform or its effective templates
change, but all six targets run before a release qualification claim.

## Delivery ledger

| Increment | Depends on | Completion signal |
| --- | --- | --- |
| A. Contracts and test harness | None | Typed protocols/models, fake adapters, journal/secret serialization guards, and unit tests. |
| B. Catalog proof (#107) | A | Sanitized fixtures, adapter and mapping tests, reviewed unresolved IDs. |
| C. Entitlement proof (#108) | A, verified content inventory | Contract tests plus authorized evidence or precise blocker for each premium path. |
| D. Installation proof (#109) | B, C (affirmative evidence for premium paths), compatibility manifests | Reproducible system-only setup and qualified premium paths without committed content; a C blocker cannot satisfy premium qualification. |
| E. Secret proof (#110) | A | Six-profile design evidence, synthetic leakage checks, restart/replacement proof, Hetzner decision. |
| F. Wizard (#111–#114) | A, C | Secure callback and approved credential lifecycle. |
| G. Plan/review (#115–#118) | B, C, F | Pinned recipe resolution and digest-bound approval. |
| H. Provider delivery (#119–#126) | D, E, G | Shared resumable flow passes for all six profiles. |
| I. Qualification/docs (#127–#130) | H | Playable-world evidence and verified operator/recovery guidance. |

Work may overlap only where dependencies allow. Premium installation stays
blocked until B and C produce affirmative evidence. Billable provisioning stays
blocked until explicit external-action authorization is recorded.

## First implementation checkpoint

The next code change should implement increment A and the fixture-driven portion
of B without calling live storefronts. Before that change is accepted, reviewers
must agree on:

1. the Python packaging/runtime versions and dependency policy;
2. the initial Cosmere and D&D recipe identifiers;
3. fixture redistribution permission and sanitization checklist;
4. the observed storefront schemas and pagination/backoff limits; and
5. which consumer entitlement paths may be exercised with authorized accounts.

If live API access or redistribution permission is unavailable, development can
continue against synthetic contract fixtures, but the corresponding capability
matrix rows remain `blocked`; synthetic results cannot be presented as an
authorized integration proof.
