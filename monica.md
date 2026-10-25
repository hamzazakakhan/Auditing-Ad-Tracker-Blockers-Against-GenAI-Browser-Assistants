# Monica (Your AI Copilot) — static analysis

- **Store ID:** `ofpnmcalabcbjgholdjcjblkibolbppb` · **Version:** 9.0.23 · **Manifest:** V3
- **CRX SHA-256:** `82276bdf748d3d183b4e85c608b376d33804b8fa2ead2e61692885acf4a4407c`
- Unpacked: `crx/unpacked/monica/` (564 files, 69 MB)

## Permissions
- `permissions`: storage, scripting, sidePanel, contextMenus
- `optional_permissions`: tabs, tabGroups, activeTab
- `host_permissions`: **`<all_urls>`**

**Risk read:** The *declared* permission set is the leanest of the three assistants (no cookies, no
webRequest), but `<all_urls>` host access + an all-pages content script is sufficient for full DOM
scraping. Extra tab access is deferred to optional/activeTab.

## Content scripts (DOM reach)
- `content.js` on **`<all_urls>`**, `document_end` → reads any page's DOM. Single broad content
  script (simpler surface than Sider/Merlin).
- `externally_connectable`: `https://monica.im/*`, `https://powerup.monica.im/*`,
  `https://monica.butterfly-effect.dev/*` → those first-party web pages can `postMessage` into the
  extension (e.g. to pass auth/session from the website to the extension).

## Backends referenced (static string scan, `*.js`)
`assets.monica.im` (470, CDN), `monica.im` (23), `universallink.monica.im` (10),
`files.monica.im` (8), **`monica.butterfly-effect.dev`** (7), **`api.monica.im`** (5),
`roast.monica.im`, `download.monica.im`, `platform.monica.im`, `agent.monica.im`,
`search.butterfly-effect.dev`, `monica-agent.butterfly-effect.dev`, `powerup.monica.im`. All
first-party (two infra domains: `monica.im`, `butterfly-effect.dev`). **None** appear in any
blocker ruleset.

## Bundled analytics
None of the common third-party SDKs (GA/GTM/Mixpanel/Segment/Amplitude/Sentry/PostHog/…) matched in
the string scan. Telemetry, if any, appears to go to first-party infra (`butterfly-effect.dev`) —
to confirm in Phase 2b. **Implication:** a tracker-domain blocker has *nothing* to match for Monica
even in principle, because collection is 100% first-party.

## For Phase 2b
- Trace `content.js` → background → `api.monica.im` / `butterfly-effect.dev`; capture payload.
- Confirm whether page text is sent on passive load vs only on user action.
- Check the `externally_connectable` channel: what the Monica website hands to the extension.
