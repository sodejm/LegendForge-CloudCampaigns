"""Loopback-only wizard with out-of-band pairing and acknowledged selections."""
from dataclasses import asdict
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from importlib.resources import files
import json
import re
import secrets
import threading
import time

from .credentials import CredentialError, CredentialRef, CredentialStore, Secret
from .catalog import CatalogAdapter, CatalogError
from .planning import PROFILES

KINDS = {"foundry-license", "foundry-username", "foundry-password", "foundry-admin",
         "gm-password", "provider-token", "cloudflare-token"}


class WizardSession:
    def __init__(self, *, store_factory=CredentialStore, catalog=None, clock=time.monotonic, ttl=900):
        self.token = secrets.token_urlsafe(32)
        self.clock, self.expires = clock, clock() + ttl
        self.store_factory = store_factory
        self.store = None
        self.connected = False
        self.cancelled = False
        self.selection = None
        self.lock = threading.Lock()
        self.catalog = catalog or CatalogAdapter()
        self.catalog_lock = threading.Lock()
        self.listings = {}

    def _catalog_request(self, body, authorization):
        with self.lock:
            if not secrets.compare_digest(authorization, "Bearer " + self.token):
                return 403, {"error": "pairing_required"}
            if self.cancelled or self.clock() >= self.expires:
                return 410, {"error": "session_ended_restart_launcher"}
            if not self.connected:
                return 409, {"error": "handshake_required"}
            if (not isinstance(body, dict) or set(body) != {"system"}
                    or body["system"] not in ("cosmere-rpg", "dnd5e")):
                return 400, {"error": "invalid_catalog_request"}
        # Network work never holds the session lock: cancellation stays responsive.
        if not self.catalog_lock.acquire(blocking=False):
            return 409, {"error": "catalog_loading_retry"}
        try:
            system = body["system"]
            records = self.catalog.search(system=system, publisher=(
                "brotherwise-games" if system == "cosmere-rpg" else None))
            with self.lock:
                if self.cancelled or self.clock() >= self.expires:
                    return 410, {"error": "session_ended_restart_launcher"}
                self.listings[system] = {item.listing_id: item for item in records}
                return 200, {"listings": [asdict(item) for item in records],
                             "notice": "Discovery only; release, package mapping and ownership require verification."}
        except CatalogError as exc:
            return 503, {"error": str(exc)}
        finally:
            self.catalog_lock.release()

    def request(self, path, body, authorization):
        if path == "/catalog":
            return self._catalog_request(body, authorization)
        with self.lock:
            if not secrets.compare_digest(authorization, "Bearer " + self.token):
                return 403, {"error": "pairing_required"}
            if self.cancelled or self.clock() >= self.expires:
                return 410, {"error": "session_ended_restart_launcher"}
            if not isinstance(body, dict):
                return 400, {"error": "invalid_request"}
            if path == "/handshake":
                # Browser capabilities are self-reported preflight, not an auth claim.
                browser = body.get("browser", "")
                if not isinstance(browser, str) or len(browser) > 2048:
                    return 400, {"error": "invalid_browser"}
                if not re.search(r"(?:Chrome|Firefox|Edg|OPR)/[0-9]+", browser):
                    return 422, {"error": "supported_browser_required"}
                if body.get("webgl2") is not True or body.get("fetch") is not True:
                    return 422, {"error": "browser_capabilities_missing"}
                self.connected = True
                return 200, {"acknowledged": True}
            if not self.connected:
                return 409, {"error": "handshake_required"}
            if path == "/cancel":
                self.cancelled = True
                return 200, {"acknowledged": True}
            if path == "/selection":
                if set(body) != {"campaign", "system", "profile", "content"}:
                    return 400, {"error": "invalid_selection"}
                if (not isinstance(body["campaign"], str)
                        or not re.fullmatch(r"[a-z0-9][a-z0-9-]{0,62}", body["campaign"])
                        or body["system"] not in ("dnd5e", "cosmere-rpg")
                        or body["profile"] not in PROFILES):
                    return 422, {"error": "invalid_selection"}
                content = body["content"]
                if (not isinstance(content, list) or len(content) > 100
                        or any(not isinstance(item, str) for item in content)
                        or len(content) != len(set(content))):
                    return 422, {"error": "invalid_content_selection"}
                available = self.listings.get(body["system"], {})
                if any(item not in available or available[item].expires_at <= self.catalog.clock()
                       for item in content):
                    return 422, {"error": "content_missing_or_stale_reload_catalog"}
                if self.selection is not None and body != self.selection:
                    return 409, {"error": "selection_locked_restart_to_change"}
                self.selection = dict(body)
                return 200, {"acknowledged": True, "selection": self.selection,
                             "deployment": "blocked_pending_preflight"}
            if path in ("/credentials/save", "/credentials/delete"):
                if self.selection is None:
                    return 409, {"error": "selection_required"}
                expected = {"account", "campaign", "kind"}
                if path.endswith("save"):
                    expected.add("value")
                if set(body) != expected or body.get("campaign") != self.selection["campaign"]:
                    return 400, {"error": "invalid_credential_request"}
                if not isinstance(body.get("kind"), str) or body["kind"] not in KINDS:
                    return 400, {"error": "invalid_credential_kind"}
                try:
                    ref = CredentialRef(body["account"], body["campaign"], body["kind"])
                    if self.store is None:
                        self.store = self.store_factory()
                    action = path.rsplit("/", 1)[-1]
                    if action == "save":
                        self.store.save(ref, Secret(body["value"]))
                    else:
                        self.store.delete(ref)
                    return 200, {"action": action, "reference": asdict(ref)}
                except CredentialError:
                    return 503, {"error": "credential_operation_failed_unlock_or_configure_OS_store"}
                finally:
                    body.pop("value", None)
            return 404, {"error": "not_found"}


class WizardServer(ThreadingHTTPServer):
    daemon_threads = True
    request_queue_size = 8

    def __init__(self, session=None):
        self.session = session or WizardSession()
        super().__init__(("127.0.0.1", 0), _Handler)
        self.origin = f"http://127.0.0.1:{self.server_port}"

    def handle_error(self, request, client_address):
        # Never emit tracebacks containing request bodies or secret backend state.
        pass


class _Handler(BaseHTTPRequestHandler):
    def setup(self):
        super().setup()
        self.connection.settimeout(5)

    def log_message(self, format, *args):
        pass

    def _reply(self, status, payload, content_type="application/json"):
        data = json.dumps(payload).encode() if content_type == "application/json" else payload
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(data)))
        self.send_header("Cache-Control", "no-store")
        self.send_header("Content-Security-Policy", "default-src 'none'; script-src 'self'; style-src 'self'; connect-src 'self'; base-uri 'none'; form-action 'self'; frame-ancestors 'none'")
        self.send_header("X-Content-Type-Options", "nosniff")
        self.send_header("Referrer-Policy", "no-referrer")
        self.send_header("Cross-Origin-Resource-Policy", "same-origin")
        self.send_header("Connection", "close")
        self.end_headers()
        self.wfile.write(data)

    def _host_valid(self):
        return self.headers.get_all("Host") == [f"127.0.0.1:{self.server.server_port}"]

    def do_GET(self):
        if not self._host_valid():
            self._reply(403, {"error": "invalid_host"})
            return
        assets = {"/": ("wizard.html", "text/html; charset=utf-8"),
                  "/wizard.js": ("wizard.js", "text/javascript; charset=utf-8"),
                  "/wizard.css": ("wizard.css", "text/css; charset=utf-8")}
        if self.path not in assets:
            self._reply(404, {"error": "not_found"})
            return
        name, kind = assets[self.path]
        self._reply(200, files("legendforge").joinpath("web", name).read_bytes(), kind)

    def do_POST(self):
        if (not self._host_valid()
                or self.headers.get_all("Origin") != [self.server.origin]
                or self.headers.get_all("Content-Type") != ["application/json"]
                or self.headers.get("Transfer-Encoding") is not None
                or len(self.headers.get_all("Authorization", [])) != 1):
            self._reply(403, {"error": "request_origin_or_headers_rejected"})
            return
        try:
            lengths = self.headers.get_all("Content-Length", [])
            if len(lengths) != 1 or not lengths[0].isdecimal():
                raise ValueError()
            size = int(lengths[0])
            if not 0 < size <= 32768:
                raise ValueError()
            raw = self.rfile.read(size)
            body = json.loads(raw)
            status, result = self.server.session.request(
                self.path, body, self.headers["Authorization"])
        except (ValueError, UnicodeError, TypeError, RecursionError):
            self._reply(400, {"error": "invalid_request"})
            return
        except TimeoutError:
            self._reply(408, {"error": "request_timeout"})
            return
        self._reply(status, result)
