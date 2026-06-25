const CSS_SERVER = 'http://localhost:8956';
const ALARM_NAME = 'fetch-matugen-css';

// Keep a cached copy of global CSS for fallback
let cachedGlobalCSS = '';

async function fetchFromServer(path) {
  try {
    const res = await fetch(`${CSS_SERVER}${path}`, { signal: AbortSignal.timeout(3000) });
    if (res.ok) return await res.text();
  } catch (e) {}
  return '';
}

async function fetchGlobalCSS() {
  cachedGlobalCSS = await fetchFromServer('/theme.css');
  await chrome.storage.local.set({ __global_css__: cachedGlobalCSS });
}

// Handle CSS fetch requests from content scripts
chrome.runtime.onMessage.addListener((msg, sender, sendResponse) => {
  if (msg.type === 'fetch-css') {
    (async () => {
      const [baseCSS, domainCSS] = await Promise.all([
        fetchFromServer('/theme.css'),
        fetchFromServer(`/${msg.domain}.css`)
      ]);
      sendResponse({ baseCSS, domainCSS });
    })();
    return true;  // keep channel open for async response
  }
  if (msg === 'refresh-css') {
    fetchGlobalCSS();
  }
});

function ensureAlarm() {
  chrome.alarms.get(ALARM_NAME, (alarm) => {
    if (!alarm) {
      chrome.alarms.create(ALARM_NAME, { periodInMinutes: 0.5 });
    }
  });
}

chrome.runtime.onInstalled.addListener(() => {
  fetchGlobalCSS();
  ensureAlarm();
});

chrome.runtime.onStartup.addListener(() => {
  fetchGlobalCSS();
  ensureAlarm();
});

chrome.alarms.onAlarm.addListener((alarm) => {
  if (alarm.name === ALARM_NAME) fetchGlobalCSS();
});
