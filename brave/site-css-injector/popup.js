document.addEventListener('DOMContentLoaded', async () => {
  const domainEl = document.getElementById('domain');
  const toggle = document.getElementById('themeToggle');
  const cssInput = document.getElementById('cssInput');
  const saveBtn = document.getElementById('saveBtn');
  const statusEl = document.getElementById('status');

  function normalizeDomain(hostname) {
    return hostname.replace(/^www\./, '');
  }

  const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
  const url = new URL(tab.url);
  const domain = normalizeDomain(url.hostname);
  domainEl.textContent = domain;

  const ENABLED_KEY = '__matugen_enabled__';

  // Load state
  const result = await chrome.storage.local.get([ENABLED_KEY, domain]);
  const enabled = result[ENABLED_KEY] || [];
  toggle.checked = enabled.includes(domain);
  cssInput.placeholder = enabled.includes(domain)
    ? 'Extra CSS overrides (appended after auto theme)...'
    : 'Enable toggle first to activate auto theme';

  // Show saved custom CSS in textarea (if any)
  if (result[domain]) {
    cssInput.value = result[domain];
  }

  // Toggle matugen auto-theme on/off
  toggle.addEventListener('change', async () => {
    const r = await chrome.storage.local.get(ENABLED_KEY);
    const list = r[ENABLED_KEY] || [];
    const idx = list.indexOf(domain);

    if (toggle.checked) {
      if (idx === -1) {
        list.push(domain);
        await chrome.storage.local.set({ [ENABLED_KEY]: list });
      }
      cssInput.placeholder = 'Extra CSS overrides (appended after auto theme)...';
      chrome.tabs.sendMessage(tab.id, { type: 'inject-css', domain }).catch(() => {});
      statusEl.textContent = 'Auto-theme enabled';
    } else {
      if (idx !== -1) {
        list.splice(idx, 1);
        await chrome.storage.local.set({ [ENABLED_KEY]: list });
        await chrome.storage.local.remove(domain);
      }
      cssInput.value = '';
      cssInput.placeholder = 'Enable toggle first to activate auto theme';
      chrome.tabs.reload(tab.id);
      statusEl.textContent = 'Disabled, tab reloading';
    }
    setTimeout(() => (statusEl.textContent = ''), 2000);
  });

  // Save custom CSS overrides for this domain
  saveBtn.addEventListener('click', async () => {
    const css = cssInput.value.trim();
    if (css) {
      await chrome.storage.local.set({ [domain]: css });
    } else {
      await chrome.storage.local.remove(domain);
    }
    chrome.tabs.sendMessage(tab.id, { type: 'inject-css', domain }).catch(() => {});
    statusEl.textContent = css ? 'Custom overrides saved!' : 'Custom overrides cleared';
    setTimeout(() => (statusEl.textContent = ''), 1500);
  });
});
