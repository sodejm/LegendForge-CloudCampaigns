"""Authoritative entitlement evidence, independent of storefront discovery."""
from dataclasses import dataclass
from enum import StrEnum
import math
from typing import Protocol


class Ownership(StrEnum):
    OWNED = "owned"
    NOT_OWNED = "not_owned"
    UNKNOWN = "unknown"
    NOT_REQUIRED = "not_required"


@dataclass(frozen=True)
class Entitlement:
    subject: str
    account_ref: str
    status: Ownership
    evidence_source: str
    checked_at: float
    valid_until: float
    reason_code: str

    def permits(self, *, subject, account_ref, protected, now, trusted_sources):
        if self.subject != subject or self.account_ref != account_ref:
            return False
        if self.evidence_source not in trusted_sources:
            return False
        timestamps = (self.checked_at, self.valid_until, now)
        if not all(type(timestamp) in (int, float) and math.isfinite(timestamp)
                   for timestamp in timestamps):
            return False
        if not self.checked_at <= now < self.valid_until:
            return False
        if self.status == Ownership.OWNED:
            return True
        return not protected and self.status == Ownership.NOT_REQUIRED


class EntitlementVerifier(Protocol):
    def verify(self, subject: str, account_ref: str) -> Entitlement: ...


class UnavailableVerifier:
    """Default until an authorized consumer verification method is proven.

    A license string, account password, store listing, or publisher API token is
    not ownership evidence. This verifier deliberately never returns owned.
    """
    def verify(self, subject, account_ref):
        return Entitlement(subject, account_ref, Ownership.UNKNOWN,
                           "unavailable", 0, 0, "authorized_verifier_not_configured")
