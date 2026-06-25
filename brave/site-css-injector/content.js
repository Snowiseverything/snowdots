function normalizeDomain(hostname) {
  return hostname.replace(/^www\./, '');
}

async function injectCSS(css) {
  if (!css) return;
  const id = 'matugen-theme';
  let style = document.getElementById(id);
  if (style) {
    style.textContent = css;
    return;
  }
  style = document.createElement('style');
  style.id = id;
  style.textContent = css;
  document.documentElement.appendChild(style);
}

function fetchCSSFromWorker(domain) {
  return new Promise((resolve) => {
    chrome.runtime.sendMessage({ type: 'fetch-css', domain }, (res) => {
      if (res) resolve(res);
      else resolve({ baseCSS: '', domainCSS: '' });
    });
  });
}

async function applyMatugenTheme(domain) {
  const { baseCSS, domainCSS } = await fetchCSSFromWorker(domain);
  let combined = [baseCSS, domainCSS].filter(Boolean).join('\n\n');

  const storage = await chrome.storage.local.get(domain);
  if (storage[domain]) {
    combined += '\n\n' + storage[domain];
  }

  await injectCSS(combined);
}

(async function () {
  const domain = normalizeDomain(location.hostname);
  const storage = await chrome.storage.local.get('__matugen_enabled__');
  const enabled = storage.__matugen_enabled__ || [];

  if (enabled.includes(domain)) {
    await applyMatugenTheme(domain);
  }
})();

chrome.runtime.onMessage.addListener((msg) => {
  if (msg.type === 'inject-css' && msg.domain === normalizeDomain(location.hostname)) {
    applyMatugenTheme(msg.domain);
  }
});
