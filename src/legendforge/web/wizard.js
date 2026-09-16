'use strict';
let token = '';
let selected = null;
const byId = id => document.getElementById(id);
const report = message => { byId('status').textContent = message; };
byId('system').addEventListener('change', () => { byId('catalog').replaceChildren(); });
byId('load-catalog').addEventListener('click', async () => {
  const system = byId('system').value;
  byId('load-catalog').disabled = true;
  report('Loading public catalog. Publisher add-ons may require several pages.');
  try {
    const result = await post('/catalog', {system});
    if (byId('system').value !== system) return;
    byId('catalog').replaceChildren();
    for (const item of result.listings) {
      const label = document.createElement('label');
      const input = document.createElement('input');
      input.type = 'checkbox'; input.name = 'content'; input.value = item.listing_id;
      label.append(input, document.createTextNode(`${item.title} — release and ownership unverified`));
      byId('catalog').append(label);
    }
    report(result.notice);
  } catch (error) { report(`Catalog unavailable: ${error.message}. You can select a system-only world.`); }
  finally { byId('load-catalog').disabled = false; }
});
async function post(path, body) {
  const response = await fetch(path, {method: 'POST', cache: 'no-store', credentials: 'omit',
    headers: {'Content-Type': 'application/json', 'Authorization': `Bearer ${token}`},
    body: JSON.stringify(body)});
  const result = await response.json();
  if (!response.ok) throw new Error(result.error || 'Request failed');
  return result;
}
byId('pair').addEventListener('submit', async event => {
  event.preventDefault();
  token = byId('pairing').value;
  try {
    const canvas = document.createElement('canvas');
    const webgl2 = !!canvas.getContext('webgl2');
    await post('/handshake', {webgl2, fetch: typeof fetch === 'function',
      browser: navigator.userAgent});
    byId('pairing').value = '';
    byId('pair').hidden = true;
    byId('setup').hidden = false;
    report('Connected. Select your game and profile.');
  } catch (error) { token = ''; report(error.message); }
});
byId('selection').addEventListener('submit', async event => {
  event.preventDefault();
  try {
    const form = new FormData(event.target);
    const body = Object.fromEntries(form);
    body.content = form.getAll('content');
    const result = await post('/selection', body);
    selected = result.selection;
    byId('chosen').textContent = `${selected.campaign}: ${selected.system} / ${selected.profile}; ${selected.content.length} content requests`;
    report('Selection acknowledged. Deployment is blocked pending verified preflight.');
  } catch (error) { report(error.message); }
});
byId('reveal').addEventListener('click', () => {
  const showing = byId('secret').type === 'password';
  byId('secret').type = showing ? 'text' : 'password';
  byId('reveal').setAttribute('aria-pressed', String(showing));
  byId('reveal').textContent = showing ? 'Hide value' : 'Show value';
});
byId('credential').addEventListener('submit', async event => {
  event.preventDefault();
  if (!selected) { report('Confirm your campaign selection first.'); return; }
  const action = event.submitter?.value || 'save';
  const body = Object.fromEntries(new FormData(event.target));
  body.campaign = selected.campaign;
  if (action === 'delete') delete body.value;
  try {
    const result = await post(`/credentials/${action}`, body);
    byId('secret').value = '';
    byId('secret').type = 'password';
    byId('reveal').setAttribute('aria-pressed', 'false');
    byId('reveal').textContent = 'Show value';
    const item = document.createElement('li');
    item.textContent = `${result.action}: ${result.reference.account} / ${result.reference.campaign} / ${result.reference.kind}`;
    byId('references').append(item);
    report(action === 'save' ? 'Saved securely. Stored values are never returned to this page.' : 'Deleted locally. Provider access is not revoked.');
  } catch (error) { report(error.message); }
  finally { delete body.value; }
});
byId('cancel').addEventListener('click', async () => {
  try { await post('/cancel', {}); } catch (error) { report(error.message); return; }
  token = ''; selected = null; byId('secret').value = ''; byId('setup').hidden = true;
  report('Setup ended. Nothing was provisioned. You can close this tab.');
});
window.addEventListener('pagehide', () => { token = ''; byId('secret').value = ''; });
