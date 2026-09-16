"""Offline trust-boundary and HTTP regression tests for campaign setup."""
import contextlib
from dataclasses import replace
import http.client
import io
import json
from pathlib import Path
import pickle
import plistlib
import sys
import tempfile
import threading
import unittest
from unittest.mock import Mock, patch
from urllib.error import HTTPError, URLError

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'src'))
from legendforge.browsers import discover
from legendforge.catalog import CatalogAdapter, CatalogError, StoreTransport
from legendforge.credentials import CredentialError, CredentialRef, CredentialStore, Secret
from legendforge.entitlements import Entitlement, Ownership, UnavailableVerifier
from legendforge.planning import Check, DeploymentPlan, PackagePin, check_ownership
from legendforge.wizard import WizardServer, WizardSession


def row(identifier='one', **kwargs):
    return dict(id=identifier, name=identifier, title='<b>Book</b>',
                description='<script>danger()</script>Useful', type='module',
                systems=['cosmere-rpg'], content_provider_id='brotherwise-games', **kwargs)


def page(rows, current=1, per_page=25, total=None):
    total = len(rows) if total is None else total
    return dict(results=rows, page=current, per_page=per_page, total=total,
                total_pages=max(1, (total + per_page - 1) // per_page))


class CatalogTests(unittest.TestCase):
    def test_cache_expiry_and_metadata_not_authority(self):
        transport = Mock(return_value=page([row()]))
        clock = Mock(return_value=100)
        adapter = CatalogAdapter(transport, clock=clock, ttl=10)
        first = adapter.search(system='cosmere-rpg')
        self.assertEqual(first[0].title, 'Book')
        self.assertEqual(first[0].description, 'Useful')
        self.assertIsNone(first[0].package_id)
        self.assertEqual(first[0].availability, 'unknown')
        self.assertEqual(adapter.search(system='cosmere-rpg'), first)
        self.assertEqual(transport.call_count, 1)
        clock.return_value = 111
        transport.side_effect = CatalogError('offline')
        with self.assertRaises(CatalogError):
            adapter.search(system='cosmere-rpg')

    def test_publisher_addon_without_system(self):
        addon = row('addon'); addon['systems'] = []
        transport = Mock(side_effect=[page([row()], 1, 1, 2), page([addon], 2, 1, 2)])
        records = CatalogAdapter(transport).search(system='cosmere-rpg', publisher='brotherwise-games')
        self.assertEqual([x.slug for x in records], ['one', 'addon'])
        self.assertEqual(transport.call_args_list[0].args[1], {'page': 1})

    def test_changed_cyclic_partial_and_bounded_pages(self):
        cases = [
            [page([row()], 1, 1, 2), page([row()], 2, 1, 2)],
            [page([row()], 1, 1, 2), page([row('two')], 2, 1, 3)],
            [page([], 1, 1, 2)],
            [page([row()], total=2)],
        ]
        for replies in cases:
            with self.subTest(replies=replies), self.assertRaises(CatalogError):
                CatalogAdapter(Mock(side_effect=replies)).search()
        with self.assertRaisesRegex(CatalogError, 'page_limit'):
            CatalogAdapter(Mock(return_value=page([row()], 1, 1, 2)), max_pages=1).search()

    def test_schema_changes_fail_closed(self):
        for change in ({'page': True}, {'results': {}}, {'total_pages': 99}):
            data = page([row()]); data.update(change)
            with self.subTest(change=change), self.assertRaises(CatalogError):
                CatalogAdapter(Mock(return_value=data)).search()
        adapter = CatalogAdapter(Mock(return_value={'publishers': [{'id': 'p', 'name': 'Publisher'}], 'systems': ['dnd5e']}))
        self.assertEqual(adapter.filters()['systems'], ('dnd5e',))
        adapter.transport.return_value['systems'] = [{'id': 'dnd5e'}]
        with self.assertRaises(CatalogError):
            adapter.filters()

    def test_retry_and_safe_errors(self):
        sleeper = Mock()
        opener = Mock()
        opener.open.side_effect = HTTPError('https://example.test', 429, 'private payload', {'Retry-After': '9999'}, None)
        with patch('legendforge.catalog.build_opener', return_value=opener):
            with self.assertRaisesRegex(CatalogError, '^service_unavailable$'):
                StoreTransport(sleep=sleeper, jitter=lambda: 0)('/api/search/filters', {})
        self.assertEqual(opener.open.call_count, 3)
        self.assertEqual([call.args[0] for call in sleeper.call_args_list], [30, 30])
        opener.open.side_effect = URLError('private payload')
        with patch('legendforge.catalog.build_opener', return_value=opener):
            with self.assertRaisesRegex(CatalogError, '^network_unavailable$'):
                StoreTransport(sleep=lambda _: None)('/api/search/filters', {})


class EntitlementPlanTests(unittest.TestCase):
    def evidence(self, **changes):
        return replace(Entitlement('foundry-license', 'account', Ownership.OWNED,
                                  'trusted', 100, 200, 'verified'), **changes)

    def test_scope_freshness_authority_and_status(self):
        params = dict(subject='foundry-license', account_ref='account', protected=True,
                      now=150, trusted_sources={'trusted'})
        self.assertTrue(self.evidence().permits(**params))
        for changes in ({'status': Ownership.UNKNOWN}, {'status': Ownership.NOT_OWNED},
                        {'status': Ownership.NOT_REQUIRED}, {'account_ref': 'other'},
                        {'evidence_source': 'store'}, {'checked_at': 151},
                        {'valid_until': 150}, {'valid_until': float('nan')}):
            with self.subTest(changes=changes):
                self.assertFalse(self.evidence(**changes).permits(**params))
        self.assertFalse(UnavailableVerifier().verify('foundry-license', 'account').permits(**params))
        free = self.evidence(status=Ownership.NOT_REQUIRED)
        self.assertTrue(free.permits(**dict(params, protected=False)))

    def test_license_required_even_for_free_system(self):
        self.assertFalse(check_ownership((), (), account_ref='account', now=150,
                                         trusted_sources={'trusted'}).passed)
        owned = self.evidence()
        self.assertTrue(check_ownership((), (owned,), account_ref='account', now=150,
                                       trusted_sources={'trusted'}).passed)
        self.assertFalse(check_ownership((), (owned, owned), account_ref='account', now=150,
                                        trusted_sources={'trusted'}).passed)

    def plan(self):
        checks = tuple(Check(code, True, 'fixture') for code in
                       ('license', 'ownership', 'packages', 'server_requirements',
                        'browser_requirements', 'runtime_secrets', 'dns_https',
                        'installation', 'cost', 'persistent_storage'))
        return DeploymentPlan('campaign', 'aws', 'game.example.com', '13.350',
                              'sha256:' + 'a' * 64, 'dnd5e',
                              (PackagePin('dnd5e', '5.0.0', 'system', False, True, True, True),),
                              'system-only-v1', (CredentialRef('account', 'campaign', 'foundry-license'),),
                              checks, '25.00', 'fixture')

    def test_plan_digest_and_package_gates(self):
        plan = self.plan()
        self.assertTrue(plan.ready)
        self.assertFalse(replace(plan, estimated_monthly_cost="unknown").ready)
        self.assertTrue(plan.approval_matches(plan.digest))
        self.assertFalse(replace(plan, profile='gcp').approval_matches(plan.digest))
        self.assertFalse(replace(plan, packages=()).ready)
        self.assertFalse(replace(plan, packages=(replace(plan.packages[0], release_verified=False),)).ready)
        self.assertFalse(replace(plan, checks=plan.checks + (plan.checks[0],)).ready)
        self.assertFalse(replace(plan, checks=plan.checks[:-1]).ready)
        with self.assertRaises(ValueError):
            replace(plan, active_servers=2)
        with self.assertRaises(ValueError):
            replace(plan, credential_refs=(Secret('synthetic-only'),))


class FakeBackend:
    def __init__(self):
        self.values = {}
    def set_password(self, service, key, value):
        self.values[(service, key)] = value
    def get_password(self, service, key):
        return self.values.get((service, key))
    def delete_password(self, service, key):
        del self.values[(service, key)]


def fake_store():
    store = object.__new__(CredentialStore)
    store._backend = FakeBackend()
    return store


class CredentialTests(unittest.TestCase):
    def test_redaction_save_replace_reuse_delete_scope(self):
        secret = Secret('synthetic-only')
        self.assertNotIn('synthetic-only', str(secret) + repr(secret))
        with self.assertRaises(CredentialError):
            pickle.dumps(secret)
        store = fake_store()
        ref = CredentialRef('account', 'campaign', 'foundry-license')
        other = replace(ref, campaign='other')
        self.assertNotEqual(ref.key, other.key)
        self.assertEqual(store.save(ref, secret), ref)
        self.assertEqual(store.read(ref).reveal(), 'synthetic-only')
        store.save(ref, Secret('replacement'))
        self.assertEqual(store.read(ref).reveal(), 'replacement')
        with self.assertRaises(CredentialError):
            store.read(other)
        store.delete(ref); store.delete(ref)
        with self.assertRaises(CredentialError):
            store.read(ref)

    def test_no_fallback_and_locked_backend_errors_redacted(self):
        with patch('importlib.import_module', side_effect=ImportError), self.assertRaises(CredentialError):
            CredentialStore()
        store = fake_store()
        store._backend = Mock()
        store._backend.set_password.side_effect = RuntimeError('synthetic-password-in-backend-error')
        with self.assertRaises(CredentialError) as error:
            store.save(CredentialRef('a', 'c', 'password'), Secret('synthetic-only'))
        self.assertNotIn('synthetic-password', str(error.exception))


class WizardTests(unittest.TestCase):
    def setUp(self):
        self.clock = Mock(return_value=10)
        self.store = fake_store()
        self.catalog = CatalogAdapter(Mock(return_value=page([row()])), clock=self.clock)
        self.session = WizardSession(store_factory=lambda: self.store, catalog=self.catalog, clock=self.clock, ttl=60)
        self.server = WizardServer(self.session)
        self.thread = threading.Thread(target=self.server.serve_forever, daemon=True)
        self.thread.start()
        self.selection = dict(campaign='campaign', system='cosmere-rpg', profile='aws', content=[])

    def tearDown(self):
        self.server.shutdown(); self.server.server_close(); self.thread.join()

    def post(self, path, body, **headers):
        default = {'Origin': self.server.origin, 'Authorization': 'Bearer ' + self.session.token,
                   'Content-Type': 'application/json'}
        default.update(headers)
        conn = http.client.HTTPConnection('127.0.0.1', self.server.server_port, timeout=3)
        conn.request('POST', path, json.dumps(body), default)
        response = conn.getresponse()
        data = json.loads(response.read())
        conn.close()
        return response.status, data

    def connect(self):
        self.assertEqual(self.post('/handshake', dict(browser='Chrome/152.0', webgl2=True, fetch=True))[0], 200)

    def test_roundtrip_and_duplicate_selection(self):
        self.assertEqual(self.post('/selection', self.selection)[0], 409)
        self.connect()
        for _ in range(2):
            status, result = self.post('/selection', self.selection)
            self.assertEqual(status, 200)
            self.assertTrue(result['acknowledged'])
            self.assertEqual(result['deployment'], 'blocked_pending_preflight')
        self.assertEqual(self.post('/selection', dict(self.selection, profile='azure'))[0], 409)

    def test_host_origin_auth_capability_stale_cancel(self):
        body = dict(browser='Chrome/152.0', webgl2=True, fetch=True)
        for headers in ({'Origin': 'https://evil.example'}, {'Host': 'evil.example'}, {'Authorization': 'Bearer wrong'}):
            self.assertEqual(self.post('/handshake', body, **headers)[0], 403)
        self.assertEqual(self.post('/handshake', dict(body, browser='Safari/605'))[0], 422)
        self.assertEqual(self.post('/handshake', dict(body, webgl2=False))[0], 422)
        self.connect()
        self.assertEqual(self.post('/cancel', {})[0], 200)
        self.assertEqual(self.post('/selection', self.selection)[0], 410)
        self.session.cancelled = False
        self.clock.return_value = 70
        self.assertEqual(self.post('/selection', self.selection)[0], 410)

    def test_content_server_validation(self):
        self.connect()
        desired = dict(self.selection, content=['one'])
        self.assertEqual(self.post('/selection', desired)[0], 422)
        self.assertEqual(self.post('/catalog', {'system': 'cosmere-rpg'})[0], 200)
        self.assertEqual(self.post('/selection', dict(desired, content=['one', 'one']))[0], 422)
        self.assertEqual(self.post('/selection', desired)[0], 200)
        self.session.selection = None
        self.catalog.clock = lambda: 1000
        self.assertEqual(self.post('/selection', desired)[0], 422)

    def test_secrets_never_returned_or_logged(self):
        self.connect(); self.post('/selection', self.selection)
        body = dict(account='account', campaign='campaign', kind='foundry-license', value='synthetic-only')
        output = io.StringIO()
        with contextlib.redirect_stderr(output), contextlib.redirect_stdout(output):
            status, result = self.post('/credentials/save', body)
        self.assertEqual(status, 200)
        self.assertNotIn(body['value'], json.dumps(result) + output.getvalue())
        ref = CredentialRef('account', 'campaign', 'foundry-license')
        self.assertEqual(self.store.read(ref).reveal(), body['value'])
        self.assertEqual(self.post('/credentials/save', dict(body, campaign='other'))[0], 400)
        self.assertEqual(self.post('/credentials/read', {k: v for k, v in body.items() if k != 'value'})[0], 404)
        body.pop('value')
        self.assertEqual(self.post('/credentials/delete', body)[0], 200)

    def test_security_headers_and_body_limits(self):
        conn = http.client.HTTPConnection('127.0.0.1', self.server.server_port)
        conn.request('GET', '/')
        response = conn.getresponse()
        self.assertEqual(response.status, 200)
        self.assertIn("frame-ancestors 'none'", response.getheader('Content-Security-Policy'))
        self.assertEqual(response.getheader('Cache-Control'), 'no-store')
        self.assertNotIn(self.session.token.encode(), response.read())
        conn.close()
        self.assertEqual(self.post('/handshake', {'large': 'x' * 33000})[0], 400)


class BrowserTests(unittest.TestCase):
    def test_mac_discovery_ignores_missing_and_invalid_versions(self):
        with tempfile.TemporaryDirectory() as folder:
            bundle = Path(folder) / 'Google Chrome.app' / 'Contents'
            (bundle / 'MacOS').mkdir(parents=True)
            (bundle / 'MacOS' / 'Google Chrome').touch()
            with (bundle / 'Info.plist').open('wb') as handle:
                plistlib.dump({'CFBundleShortVersionString': '152.0.1'}, handle)
            browsers = discover(platform='darwin', app_roots=[folder])
            self.assertEqual([(b.family, b.version) for b in browsers], [('Chrome', '152.0.1')])
            with (bundle / 'Info.plist').open('wb') as handle:
                plistlib.dump({'CFBundleShortVersionString': 'invalid'}, handle)
            self.assertEqual(discover(platform='darwin', app_roots=[folder]), ())

    def test_linux_discovery_dedupes_and_bounds_execution(self):
        run = Mock(return_value=Mock(stdout='Chromium 150.0.1'))
        browsers = discover(platform='linux', which=lambda _: '/synthetic/chrome', run=run)
        self.assertEqual(len(browsers), 1)
        self.assertEqual(run.call_args.kwargs['timeout'], 5)


if __name__ == '__main__':
    unittest.main()
