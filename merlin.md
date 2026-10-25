# Merlin (Ask AI to Research, Write & Review) — static analysis

- **Store ID:** `camppjleccjaphfdbohjdohecfnoikec` · **Version:** 8.3.0 · **Manifest:** V3
- **CRX SHA-256:** `e7e6ba786e9ba9c68ce73642f5a6e8d65c686f6c638692e2b0871b9b814e3b8d`
- Unpacked: `crx/unpacked/merlin/` (475 files, 18 MB) · Developer: Foyer Tech

## Permissions
- `permissions`: sidePanel, storage, contextMenus, tabs, alarms, **webNavigation**, **webRequest**,
  scripting
- `optional_permissions`: identity
- `host_permissions`: `https://*/*` (+ optional `<all_urls>`)

**Risk read:** Has `webRequest` (observe) + `webNavigation` — more network/navigation visibility
than Monica. `identity` (optional) for OAuth. Note `webRequest` here is observe-only in MV3 (Phase 1
§a); it does not let Merlin block, and does not let it see *other* extensions' requests.

## Content scripts (DOM reach)
- On **`<all_urls>`** (document_idle): `askMerlinSelection.js`, `blog-summarizer.js`,
  `floatingCTA.js`, **`giveFreely.js`**, `main.js` → full DOM read on every page.
- Site-specific strippers: `gmailStrip.js` (Gmail), `linkedinStrip.js` (LinkedIn),
  `twitterStrip.js` (X/Twitter) — targeted content extraction from webmail/social.
- `youtube-pot.js` on YouTube in **`world: MAIN`** (page world), plus `youtube.js` isolated.
- `externally_connectable`: `*.getmerlin.in`, `*.foyer.work`.

### ⚠ Third-party SDK bundled as a content script: `giveFreely.js`
`giveFreely` is a third-party **affiliate/shopping-data monetization** SDK that runs on `<all_urls>`.
This is a distinct data pathway from Merlin's own AI backend and deserves its own data-flow trace in
Phase 2b (what it reads, what domain it sends to). Flag for the report as a third-party collector
riding inside an "AI assistant."

## Backends referenced (static string scan, `*.js`)
`www.getmerlin.in` (11), `getmerlin.in` (7), `feedback.getmerlin.in` (4), `cdn.getmerlin.in` (1).
API host likely a `getmerlin.in` subdomain and/or `foyer.work` (externally_connectable) — resolve
exactly in Phase 2b. None appear in any blocker ruleset.

## Bundled analytics
`google-analytics.com` (4 refs) → third-party GA present (on uBO Lite's lists). Plus the
`giveFreely` pathway above.

## For Phase 2b
- Resolve Merlin's exact AI API host (getmerlin.in subdomain vs foyer.work) and trace payload.
- **`giveFreely.js`**: full data-flow (reads, destination domain, consent) — likely the most
  interesting third-party-collection finding among the assistants.
- Site strippers (Gmail/LinkedIn/X): what fields are extracted and where they go.
