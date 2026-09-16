"""OS-only credential storage. Errors and return values never contain secrets."""
from dataclasses import dataclass
import hashlib
import json
import re


class CredentialError(Exception):
    pass


class Secret:
    """Reduce accidental disclosure; Python does not promise memory zeroization."""
    __slots__ = ("_value",)

    def __init__(self, value):
        if not isinstance(value, str) or not value or len(value) > 16384:
            raise CredentialError("invalid_secret")
        self._value = value

    def __repr__(self):
        return "<Secret redacted>"

    def __str__(self):
        return "<Secret redacted>"

    def reveal(self):
        """Only for immediate delivery to an authorized secret consumer."""
        return self._value

    def __reduce__(self):
        raise CredentialError("secret_serialization_forbidden")


@dataclass(frozen=True)
class CredentialRef:
    account: str
    campaign: str
    kind: str

    def __post_init__(self):
        for value in (self.account, self.campaign, self.kind):
            if not isinstance(value, str) or not re.fullmatch(r"[A-Za-z0-9_-]{1,80}", value):
                raise CredentialError("invalid_credential_reference")

    @property
    def key(self):
        canonical = json.dumps([self.account, self.campaign, self.kind], separators=(",", ":"))
        return hashlib.sha256(canonical.encode()).hexdigest()


# Exact class identity is checked, not user-configurable names or priority alone.
_BACKENDS = {
    "darwin": (("keyring.backends.macOS", "Keyring"),),
    "linux": (("keyring.backends.SecretService", "Keyring"),
              ("keyring.backends.kwallet", "DBusKeyring"),
              ("keyring.backends.kwallet", "DBusKeyringKWallet4")),
}


class CredentialStore:
    SERVICE = "org.legendforge.campaigns.v1"

    def __init__(self):
        import importlib
        import sys
        self._backend = None
        for module, name in _BACKENDS.get(sys.platform, ()):
            try:
                backend_type = getattr(importlib.import_module(module), name)
                backend = backend_type()
                if type(backend) is backend_type and backend.priority > 0:
                    self._backend = backend
                    break
            except Exception:
                continue
        if self._backend is None:
            raise CredentialError("os_store_unavailable_unlock_or_configure")

    def _call(self, operation, *args):
        try:
            return getattr(self._backend, operation)(self.SERVICE, *args)
        except Exception:
            # Backend exceptions can contain passwords, DBus payloads or paths.
            raise CredentialError("os_store_operation_failed_unlock_or_configure") from None

    def save(self, ref: CredentialRef, secret: Secret):
        if not isinstance(ref, CredentialRef) or not isinstance(secret, Secret):
            raise CredentialError("invalid_credential")
        self._call("set_password", ref.key, secret.reveal())
        return ref

    def read(self, ref: CredentialRef):
        value = self._call("get_password", ref.key)
        if value is None:
            raise CredentialError("credential_not_found")
        return Secret(value)

    def delete(self, ref: CredentialRef):
        # Idempotent deletion supports retry after a lost callback response.
        if self._call("get_password", ref.key) is not None:
            self._call("delete_password", ref.key)
