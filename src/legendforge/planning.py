"""Nonsecret plan contract and fail-closed preflight.

No plan produced here can apply infrastructure: runtime adapters and authorized
Foundry integrations must first supply verified evidence.
"""
from dataclasses import asdict, dataclass
import hashlib
import json
import re
from .credentials import CredentialRef
from .entitlements import Entitlement

PROFILES = ("aws", "aws-low-cost", "gcp", "gcp-low-cost", "azure", "hetzner")


@dataclass(frozen=True)
class PackagePin:
    package_id: str
    version: str
    kind: str
    protected: bool
    release_verified: bool = False
    compatibility_verified: bool = False
    dependencies_verified: bool = False


@dataclass(frozen=True)
class Check:
    code: str
    passed: bool
    message: str


@dataclass(frozen=True)
class DeploymentPlan:
    campaign: str
    profile: str
    hostname: str
    foundry_version: str
    image_digest: str
    system: str
    packages: tuple[PackagePin, ...]
    recipe: str
    credential_refs: tuple[CredentialRef, ...]
    checks: tuple[Check, ...]
    estimated_monthly_cost: str
    cost_source: str
    active_servers: int = 1
    schema_version: int = 1

    def __post_init__(self):
        if type(self.schema_version) is not int or self.schema_version != 1:
            raise ValueError("unsupported schema version")
        if self.profile not in PROFILES or self.system not in ("dnd5e", "cosmere-rpg"):
            raise ValueError("unsupported profile or system")
        if self.active_servers != 1:
            raise ValueError("campaigns require one active server")
        if not re.fullmatch(r"[a-z0-9][a-z0-9-]{0,62}", self.campaign):
            raise ValueError("invalid campaign identifier")
        if not re.fullmatch(r"(?=.{1,253}$)(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,63}", self.hostname):
            raise ValueError("invalid hostname")
        if not re.fullmatch(r"[0-9]+(?:\.[0-9]+){1,2}", self.foundry_version):
            raise ValueError("Foundry version must be pinned")
        if not re.fullmatch(r"sha256:[0-9a-f]{64}", self.image_digest):
            raise ValueError("image digest must be pinned")
        ids = [p.package_id for p in self.packages]
        if len(ids) != len(set(ids)):
            raise ValueError("duplicate package")
        for package in self.packages:
            if not re.fullmatch(r"[a-z0-9][a-z0-9_-]*", package.package_id):
                raise ValueError("invalid package identifier")
            if not re.fullmatch(r"[0-9]+(?:\.[0-9]+){0,3}(?:-[a-zA-Z0-9.-]+)?", package.version):
                raise ValueError("package version must be pinned")
            if package.kind not in ("module", "system", "world"):
                raise ValueError("invalid package kind")
        # Explicit typed references prevent accidental serialization of Secret.
        if any(type(ref) is not CredentialRef for ref in self.credential_refs):
            raise ValueError("credential references required")

    def canonical(self):
        return json.dumps(asdict(self), sort_keys=True, separators=(",", ":"), allow_nan=False)

    @property
    def digest(self):
        return hashlib.sha256(self.canonical().encode()).hexdigest()

    @property
    def ready(self):
        required = {"license", "ownership", "packages", "server_requirements",
                    "browser_requirements", "runtime_secrets", "dns_https",
                    "installation", "cost", "persistent_storage"}
        codes = [check.code for check in self.checks]
        return (len(codes) == len(set(codes)) and required <= set(codes)
                and all(c.passed is True for c in self.checks)
                and sum(p.kind == "system" and p.package_id == self.system for p in self.packages) == 1
                and all(p.release_verified is True and p.compatibility_verified is True
                        and p.dependencies_verified is True for p in self.packages)
                and bool(self.recipe) and bool(self.cost_source)
                and re.fullmatch(r"[0-9]+(?:\.[0-9]{1,2})?", self.estimated_monthly_cost) is not None
                and all(ref.campaign == self.campaign for ref in self.credential_refs))

    def approval_matches(self, approved_digest):
        return self.ready and self.digest == approved_digest


def check_ownership(packages, evidence: tuple[Entitlement, ...], *, account_ref,
                    now, trusted_sources):
    """License ownership is required even for a system-only campaign."""
    requirements = [("foundry-license", True)] + [(p.package_id, p.protected) for p in packages]
    missing = []
    for subject, protected in requirements:
        matches = [e for e in evidence if e.subject == subject and e.account_ref == account_ref]
        if len(matches) != 1 or not matches[0].permits(
                subject=subject, account_ref=account_ref, protected=protected,
                now=now, trusted_sources=trusted_sources):
            missing.append(subject)
    return Check("ownership", not missing,
                 "Ownership verified" if not missing else "Ownership missing or unknown: " + ", ".join(missing))
