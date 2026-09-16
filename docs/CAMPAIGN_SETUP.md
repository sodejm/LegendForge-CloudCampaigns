# Local campaign setup (development)

This is the first implementation slice of [epic #106](https://github.com/sodejm/LegendForge-CloudCampaigns/issues/106). It supports catalog discovery, acknowledged game selection, and local credential management. **It cannot provision infrastructure, verify premium ownership, install packages, or launch a world yet.** The six profile choices identify intended targets; they are not an end-to-end support claim.

## Run locally

Use Python 3.11 or later on macOS or Linux:

```sh
python3 -m venv .venv
. .venv/bin/activate
python3 -m pip install -e '.[credentials]'
legendforge browsers
legendforge wizard
```

Open the printed loopback URL in an installed Chrome, Firefox, Edge, or Opera browser, then paste the separately printed pairing code. The code expires after 15 minutes. The launcher stays running until End setup, timeout, or Ctrl-C. To launch a specific discovered executable, pass its exact path with `legendforge wizard --browser PATH`. No token or credential is placed in the URL or browser command arguments. Prefer a private terminal rather than recorded/shared console output for pairing.

The launcher discovers candidate browser executables and versions. The page checks WebGL 2 and fetch support and requires an authenticated handshake before accepting a selection. Default-browser preference, authoritative version policy, and native Firefox/Linux qualification remain outstanding under #111–112. Browser launch alone does not acknowledge a selection.

Choose a campaign identifier, game system, and deployment profile. Find game content retrieves public catalog records; Cosmere searches both system records and Brotherwise publisher content. Selected records must belong to the current server-side catalog snapshot. Catalog records are discovery metadata, not proof of release, actual Foundry package identity, compatibility, or ownership. Preorders and unverified records cannot authorize installation. Confirm selection displays a server acknowledgment; it does not deploy.

## Credentials

After selection, enter an account alias, credential kind, and secret. The masked field supports paste and password-manager input, with an accessible show/hide button. Save replaces the matching account/campaign/kind entry; successful saves clear the field and return only a reference. Delete removes that local entry. **Local deletion does not revoke a provider credential.** Server-side reuse is available through the credential-store interface; stored values are never returned to the browser.

Supported backend allowlist:

- macOS Keychain through Python keyring's macOS backend.
- Linux Secret Service or KWallet through their named keyring backends.

Install the credentials extra and configure/unlock the desktop credential store. On Linux a working desktop D-Bus session and the selected backend's dependencies are required. If no allowed backend is available, or access fails, saving is blocked. There is no plaintext fallback. Native backend qualification remains outstanding; automated lifecycle tests use an in-memory test double.

Secrets remain in process memory while being handled; the redacted Python wrapper does not promise memory zeroization. Do not paste credentials into command arguments, plans, tfvars, cloud-init, support reports, or source control. This wizard deliberately has no bridge to the legacy Terraform credential inputs. Runtime secret delivery must be proven for each provider before enabling that bridge (#110).

## Security and recovery behavior

The server binds only to `127.0.0.1` on a random port and serves bundled assets without third-party scripts. POST requests require a per-run bearer token, exact Host and Origin, JSON content type, bounded request size, and an active session. Responses disable caching and apply a restrictive content security policy. Credentials have no read-back endpoint. Request logs and backend exceptions do not expose secret values.

Duplicate identical selections return the same acknowledgment. Changed selections, stale catalog IDs, expired sessions, cancellation, and unauthenticated or cross-origin submissions are rejected. Restart the launcher to begin a new selection. Saved OS credentials remain available by their account/campaign/kind scope; selections are intentionally held only for the current process.

Catalog errors are actionable failures rather than permission to use stale metadata. Retry discovery after a network or service failure. The adapter bounds pagination and response size, validates responses, caches in memory for five minutes, and backs off on rate limits and transient failures. The store endpoints are observable interfaces without a verified public support contract.

## Remaining release gates

| Gate | Work remaining |
| --- | --- |
| M1, #107–110 | Authoritative package mapping, consumer entitlement proof, versioned installation/world integration, and secure runtime delivery for all providers. Public catalog metadata and pasted codes cannot establish ownership. |
| M2, #111–114 | Default-browser policy, native browser callback qualification, and real Keychain/Secret Service/KWallet lifecycle qualification. |
| M3, #115–118 | Manifest dependency/compatibility resolver, server/browser requirements policy, pinned recipes, cost review UI, and expiring authoritative preflight evidence. The nonsecret plan contract is an internal foundation, not an apply authorization service. |
| M4, #119–126 | DNS/HTTPS/tunnel reconciliation, resumable installation, and all six profile adapters with one active server, persistent storage, secure bootstrap, and replacement recovery. |
| M5, #127–130 | World creation/import, GM launch, authorized live end-to-end qualification, and final operator/wiki guidance. |

The entitlement model explicitly represents owned, not owned, unknown, and not required. Its default verifier returns unknown. Protected content and the Foundry license require fresh, trusted evidence. The plan contract separates credential references from secret values, pins versions and image digest, requires a single active server, and binds review to a canonical plan digest. No apply entry point is implemented.

Live cloud tests, paid provisioning, purchasing, and license acceptance require explicit user action/authorization. Premium integration also requires authorized test entitlements and a demonstrated consumer installation path. Do not claim full end-to-end support until every profile passes the release matrix.

## Validation

```sh
python3 -m unittest discover -s tests -p 'test_*.py'
pre-commit run --all-files
```

HTTP tests need permission to bind a local loopback socket. Tests use synthetic credentials and fake backend objects, never real account secrets. Coverage includes catalog schema/pagination/cache/backoff, entitlement states, plan review digest, secret lifecycle/redaction, browser discovery fixtures, and callback authentication/origin/staleness/idempotency.

A read-only live catalog smoke check on 2026-09-15 returned 62 system filters and 13 combined Cosmere/Brotherwise records. This demonstrates discovery only. Native browser automation was interrupted before manual callback/paste verification completed; it is not counted as a passing browser test. No live cloud or native credential-store validation was performed.

## Implementation checkpoint

The initial implementation is on `codex/campaign-setup`, in `/private/tmp/legendforge-campaign-setup`, based on `89db25c`. It adds the `src/legendforge/` Python package, bundled browser assets, packaging metadata, campaign regression tests, and the setup/wiki guides. The original checkout's unrelated changes remain untouched. This is local work; no code has been pushed or deployed.

On 2026-09-15, the repository acceptance suite passed all 93 tests. Pre-commit checks passed for every changed file, including secret scanning and wiki navigation validation. An explicit Semgrep scan of the new source and campaign tests completed with zero findings. A wheel build and smoke check confirmed the CLI and all three bundled wizard assets. Terraform resources were not changed, so no provider validation or live provisioning result is claimed.

Next, resolve #108's authoritative consumer entitlement and authorized installation path with test entitlements, documenting unsupported cases as blockers. Keep deployment disabled until that proof, secure runtime delivery, and the remaining preflight gates are implemented. The browser and native credential-store qualifications above also remain open; this checkpoint does not complete any milestone.
