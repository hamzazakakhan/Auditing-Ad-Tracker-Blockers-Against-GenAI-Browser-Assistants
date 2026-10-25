# Phase 2 — Static analysis summary

All CRX downloaded 2026-10-19 (hashes: `crx/HASHES.md`), unpacked under `crx/unpacked/<name>/`
(gitignored, untrusted). Every target that is installable from the Web Store on Chrome 139 is
**Manifest V3**. Classic MV2 uBlock Origin is **not served** (HTTP 204) — see `crx/HASHES.md`.

## Assistants

| | Sider 5.35.1 | Monica 9.0.23 | Merlin 8.3.0 |
|---|---|---|---|
| manifest | V3 | V3 | V3 |
| host_permissions | `<all_urls>` + `*.openai.com` | `<all_urls>` | `https://*/*` (+ opt `<all_urls>`) |
| content script on **all pages** | `content-all.js` (all_frames, document_end) | `content.js` (document_end) | `main.js` + 4 more (document_idle) |
| notable perms | **`cookies`**, `userScripts`, `scripting`, `offscreen`, `tabCapture`(opt), `declarativeNetRequest` | `scripting`, `sidePanel`; `tabs`/`activeTab`(opt) | `webRequest`, `webNavigation`, `scripting`, `identity`(opt) |
| MAIN-world injection | yes — `inject-xhr-hack.js`, `inject-json-hack.js` (YouTube/Netflix) | no | yes — `youtube-pot.js` (MAIN) |
| externally_connectable | none | monica.im, powerup.monica.im, butterfly-effect.dev | getmerlin.in, foyer.work |
| own backends (static) | sider.ai, ask.sider.ai, **event.sider.ai** (telemetry) | **api.monica.im**, platform/agent.monica.im, butterfly-effect.dev | getmerlin.in, feedback.getmerlin.in |
| bundled analytics | **Google Analytics** (GA + GTM) | none of the common SDKs matched | **Google Analytics**; **`giveFreely.js`** affiliate SDK bundled as content script |

> All three inject a content script into **every page** (`<all_urls>`) → full DOM read reach
> (Phase 1 §c). This is the capability the research question is about.

## Blockers

| | uBO Lite 2026.1018.2229 | Privacy Badger 2026.9.15.2 | MB Browser Guard 3.3.7 |
|---|---|---|---|
| manifest | V3 | V3 | V3 |
| blocking mechanism | **DNR only** (no webRequest perm) | DNR + `webRequest`(observe) + heuristic content scripts | DNR + `webRequest` + `nativeMessaging` |
| enabled rulesets (default) | ublock-filters, easylist, **easyprivacy**, pgl, ublock-badware, urlhaus | dnt_policy, gen204, bypass_redirects, ignore (small) + **dynamic learning** | whitelist, arw, always_allow; **ads/easylist/easyprivacy DISABLED by default** |
| content scripts | none | fingerprinting/supercookie/socialwidget detectors (all_urls) | `content-scripts.js` (all_urls) + site-specific |
| host_permissions | `<all_urls>` | `<all_urls>` | `<all_urls>` |

## The cross-reference that answers the question (static)

Searched every **enabled-by-default** blocker ruleset for the assistant domains:

| domain | uBO Lite | Privacy Badger (static) | MB (easyprivacy, **disabled**) |
|---|---|---|---|
| `sider.ai` | **0** | 0 | 0 |
| `monica.im` | **0** | 0 | 0 |
| `getmerlin.in` | **0** | 0 | 0 |
| `foyer.work` | **0** | 0 | 0 |
| `google-analytics.com` | 29 | 0 (learned at runtime) | 0 |
| `googletagmanager` | 45 | 0 | 1 |

**Reading:** No blocker's static ruleset lists any assistant's **first-party** backend — the exact
host that receives scraped DOM content. uBO Lite *does* list Google Analytics / GTM, so an
assistant's **third-party GA telemetry** is a candidate for blocking — *if* that request is even
visible to uBO's DNR (Phase 1 §b: a request from the assistant's own service worker, initiator
`chrome-extension://<assistant>`, is not evaluated by another extension's ruleset). That tension —
list coverage exists but visibility may not — is exactly what Phase 4 will measure.

Privacy Badger keeps near-empty static lists by design: it *learns* third-party trackers
heuristically at runtime, so static coverage of GA is 0 but runtime behaviour differs (test in
Phase 4/5). MB Browser Guard ships easylist/easyprivacy but **disabled by default**, so out of the
box it blocks far less than its bundle suggests.

## Carried into Phase 2b (RE / data-flow)
- Confirm each assistant's DOM-read → send path and whether egress is from the **service worker**
  (hidden from blockers) or the **content script world** (potentially visible). (Phase 1 §b caveat.)
- Sider `cookies` + `<all_urls>`: what cookie reads happen and where they go.
- Merlin `giveFreely.js`: what this third-party SDK collects/sends.
- Sider/Merlin GA: endpoints + payload (does page content ride GA events?).
- MB `nativeMessaging` host (cf. prior Malwarebytes RE in memory) — static only, no credential use.
