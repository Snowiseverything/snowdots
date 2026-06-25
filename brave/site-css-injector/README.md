## Site CSS Injector

A simple Brave/Chrome extension to inject custom CSS into specific websites.

## Features
- Add custom CSS per site.
- Automatically applies your CSS whenever you visit that site.
- Simple popup editor interface.

## Installation
1. Download or clone this repo
2. Open **Brave → Extensions → Manage Extensions**.
3. Enable **Developer Mode** (top right).
4. Click **Load unpacked** and select this folder.

## Usage
1. Go to any website.
2. Click the extension icon in the toolbar.
3. Enter your CSS in the textarea.
4. Click **Save & Apply**.
5. Reload the page to see your styles automatically applied.

## Files
- `manifest.json` – Extension configuration.
- `popup.html` – UI for editing CSS.
- `popup.js` – Logic for saving and injecting CSS.
- `content.js` – Automatically injects saved CSS when visiting a site.
- `storage.js` – Handles background tasks.

## License
MIT
