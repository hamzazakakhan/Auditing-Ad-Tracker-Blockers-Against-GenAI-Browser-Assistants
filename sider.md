# Sider (ChatGPT Sidebar) — static analysis

- **Store ID:** `difoiogjjojoaoomphldepapgpbgkhkb` · **Version:** 5.35.1 · **Manifest:** V3
- **CRX SHA-256:** `6cb08a28b0d2a44dec5d11d2f2272c8eb8c735b5ac3eb83f00260b31bf20bd5a`
- Unpacked: `crx/unpacked/sider/` (316 files, 94 MB)

## Permissions
- `permissions`: storage, **cookies**, contextMenus, scripting, **userScripts**, activeTab,
  unlimitedStorage, tabs, sidePanel, offscreen, alarms, declarativeNetRequest
- `optional_permissions`: tabCapture, tabGroups
- `host_permissions`: `https://*.openai.com/`, **`<all_urls>`**

**Risk read:** `<all_urls>` + `cookies` means Sider can read cookies for every site, not just read the
DOM. `userScripts` + `offscreen` + `tabCapture`(opt) are powerful (arbitrary user-script execution,
offscreen documents, tab audio/video capture). `declarativeNetRequest` present (it can shape its own
request matching) but that does not let it see *other* extensions' traffic (Phase 1 §b).

## Content scripts (DOM reach)
- `content-all.js` on **`<all_urls>`**, `all_frames: true`, `document_end` → reads any page's DOM,
  including sub-frames. This is the primary scraping surface.
- `all-frames.js` on `<all_urls>` document_start (all_frames).
- **MAIN-world page hooks:** `inject-xhr-hack.js` (YouTube, document_start, `world: MAIN`) and
  `inject-json-hack.js` (Netflix, `world: MAIN`) — these run in the *page's* JS world and hook
  `XMLHttpRequest`/JSON parsing to capture page-internal data streams (e.g. captions, catalog JSON).
  `assets/gdocs.js` MAIN-world on Google Docs. Search-engine content script on all major search
  engines (Google/Bing/DDG/Yandex/…).
- `externally_connectable`: none declared.

## Backends referenced (static string scan, `*.js`)
`sider.ai` (288), `preview.sider.ai` (23), **`event.sider.ai`** (21, telemetry-looking),
`ask.sider.ai` (7), `pub-cdn.sider.ai` (3). All **first-party** — none appear in any blocker's
ruleset (`analysis/_summary.md`).

## Bundled analytics
`google-analytics.com` (23 refs) + `www.googletagmanager.com` (2). So Sider also emits **third-party
GA**, which *is* on uBO Lite's lists — candidate for blocking subject to visibility (Phase 4).

## For Phase 2b
- Trace `content-all.js` → background `fetch` to `sider.ai`/`event.sider.ai`; capture payload fields.
- `cookies` reads: what is read, and is any cookie data sent to `event.sider.ai`?
- GA path: is page content/text attached to GA events, or only usage metrics?
- MAIN-world XHR/JSON hooks: what page data they capture and forward.
