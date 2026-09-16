"""Replaceable, read-only adapter for the observed Foundry Store JSON interface.

Store metadata is discovery evidence only. Slugs are not verified package IDs.
"""
from collections import OrderedDict
from dataclasses import dataclass
from html.parser import HTMLParser
import json
import random
import re
import time
from typing import Callable, Protocol
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode
from urllib.request import HTTPRedirectHandler, Request, build_opener

BASE = "https://www.foundryvtt.store"
ADAPTER_VERSION = "foundry-store-v1"
MAX_RESPONSE_BYTES = 4 * 1024 * 1024


class CatalogError(Exception):
    """Safe diagnostic: never includes a remote body or exception payload."""


class _NoRedirect(HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


class Transport(Protocol):
    def __call__(self, path: str, query: dict) -> dict: ...


class StoreTransport:
    def __init__(self, *, sleep=time.sleep, jitter=random.random):
        self.sleep, self.jitter = sleep, jitter

    def __call__(self, path, query):
        if path not in ("/api/search/filters", "/api/fvtt/packages/module/search"):
            raise CatalogError("unsupported_endpoint")
        request = Request(BASE + path + "?" + urlencode(query), headers={
            "Accept": "application/json", "User-Agent": "LegendForge/0.1"})
        for attempt in range(3):
            try:
                with build_opener(_NoRedirect).open(request, timeout=15) as response:
                    if response.headers.get_content_type() != "application/json":
                        raise CatalogError("unexpected_content_type")
                    raw = response.read(MAX_RESPONSE_BYTES + 1)
                    if len(raw) > MAX_RESPONSE_BYTES:
                        raise CatalogError("response_too_large")
                    value = json.loads(raw)
                    if not isinstance(value, dict):
                        raise CatalogError("invalid_response")
                    return value
            except HTTPError as exc:
                exc.close()
                if exc.code not in (429, 500, 502, 503, 504):
                    raise CatalogError("http_error") from None
                if attempt == 2:
                    raise CatalogError("service_unavailable") from None
                retry = exc.headers.get("Retry-After", "") if exc.headers else ""
                delay = min(30, int(retry)) if retry.isdecimal() else 2 ** attempt
                self.sleep(delay + self.jitter())
            except (URLError, TimeoutError, OSError):
                if attempt == 2:
                    raise CatalogError("network_unavailable") from None
                self.sleep(2 ** attempt + self.jitter())
            except (ValueError, UnicodeError):
                raise CatalogError("invalid_json") from None
        raise CatalogError("service_unavailable")


class _Text(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.parts = []
        self.hidden = 0

    def handle_starttag(self, tag, attrs):
        if tag in ("script", "style"):
            self.hidden += 1

    def handle_endtag(self, tag):
        if tag in ("script", "style") and self.hidden:
            self.hidden -= 1

    def handle_data(self, data):
        if not self.hidden:
            self.parts.append(data)


def plain_text(value):
    parser = _Text()
    parser.feed(value)
    return " ".join("".join(parser.parts).split())[:4096]


def _string(value, *, slug=False):
    if not isinstance(value, str) or not value or len(value) > 4096:
        raise CatalogError("invalid_record")
    if slug and not re.fullmatch(r"[a-zA-Z0-9_-]+", value):
        raise CatalogError("invalid_identifier")
    return value


@dataclass(frozen=True)
class Listing:
    listing_id: str
    slug: str
    title: str
    description: str
    publisher_id: str
    systems: tuple[str, ...]
    observed_at: float
    expires_at: float
    source: str = BASE
    adapter_version: str = ADAPTER_VERSION
    package_id: str | None = None
    availability: str = "unknown"
    # Required/optional is a recipe decision, separate from release availability.


class CatalogAdapter:
    def __init__(self, transport: Transport | None = None, *, clock=time.time,
                 ttl=300, max_pages=100, cache_size=32):
        if ttl <= 0 or max_pages < 1 or cache_size < 1:
            raise ValueError("invalid cache or pagination configuration")
        self.transport = transport or StoreTransport()
        self.clock, self.ttl = clock, ttl
        self.max_pages, self.cache_size = max_pages, cache_size
        self._cache = OrderedDict()

    def filters(self):
        data = self.transport("/api/search/filters", {})
        if not isinstance(data.get("publishers"), list) or not isinstance(data.get("systems"), list):
            raise CatalogError("invalid_filters")
        publishers = []
        for item in data["publishers"]:
            if not isinstance(item, dict):
                raise CatalogError("invalid_filters")
            publishers.append((_string(item.get("id"), slug=True), _string(item.get("name"))))
        return {"publishers": tuple(publishers),
                "systems": tuple(_string(item, slug=True) for item in data["systems"])}

    def search(self, *, system=None, publisher=None):
        """Publisher discovery scans the unfiltered catalog to avoid missing add-ons.

        No undocumented publisher query parameter is assumed. Exhausting the page
        bound fails explicitly; a partial result must not look complete.
        """
        for value in (system, publisher):
            if value is not None:
                _string(value, slug=True)
        key = (ADAPTER_VERSION, system, publisher)
        now = self.clock()
        if key in self._cache:
            expires, records = self._cache[key]
            if now < expires:
                self._cache.move_to_end(key)
                return records
            del self._cache[key]
        records, seen = [], set()
        total = None
        page_count = None
        for page in range(1, self.max_pages + 1):
            query = {"page": page}
            if system and not publisher:
                query["systems"] = system
            data = self.transport("/api/fvtt/packages/module/search", query)
            for field in ("page", "per_page", "total", "total_pages"):
                if type(data.get(field)) is not int or data[field] < 0:
                    raise CatalogError("invalid_pagination")
            if data["page"] != page or not 1 <= data["per_page"] <= 1000:
                raise CatalogError("invalid_pagination")
            expected_pages = (data["total"] + data["per_page"] - 1) // data["per_page"]
            if data["total_pages"] != max(1, expected_pages) and not (
                    data["total"] == 0 and data["total_pages"] == 0):
                raise CatalogError("invalid_pagination")
            if total is not None and (total != data["total"] or page_count != data["total_pages"]):
                raise CatalogError("catalog_changed_retry")
            total, page_count = data["total"], data["total_pages"]
            rows = data.get("results")
            if not isinstance(rows, list) or len(rows) > data["per_page"]:
                raise CatalogError("invalid_results")
            for row in rows:
                record = self._normalize(row, now)
                if record.listing_id in seen:
                    raise CatalogError("duplicate_or_cyclic_page")
                seen.add(record.listing_id)
                if publisher:
                    include = record.publisher_id == publisher or (
                        system is not None and system in record.systems)
                else:
                    include = system is None or system in record.systems
                if include:
                    records.append(record)
            if page >= page_count:
                if len(seen) != total:
                    raise CatalogError("incomplete_results")
                result = tuple(records)
                self._cache[key] = (now + self.ttl, result)
                while len(self._cache) > self.cache_size:
                    self._cache.popitem(last=False)
                return result
            if not rows:
                raise CatalogError("empty_intermediate_page")
        raise CatalogError("page_limit_exceeded")

    def _normalize(self, row, now):
        if not isinstance(row, dict) or row.get("type") != "module":
            raise CatalogError("invalid_record")
        systems = row.get("systems")
        if not isinstance(systems, list):
            raise CatalogError("invalid_systems")
        description = row.get("description") or ""
        if not isinstance(description, str):
            raise CatalogError("invalid_description")
        return Listing(
            listing_id=_string(row.get("id"), slug=True),
            slug=_string(row.get("name"), slug=True),
            title=plain_text(_string(row.get("title"))),
            description=plain_text(description),
            publisher_id=_string(row.get("content_provider_id"), slug=True),
            systems=tuple(_string(x, slug=True) for x in systems),
            observed_at=now, expires_at=now + self.ttl)
