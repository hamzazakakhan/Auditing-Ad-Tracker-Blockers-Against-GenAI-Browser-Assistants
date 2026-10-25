# Privacy Badger (EFF) — static analysis

- **Store ID:** `pkehgijcmpdhfbdbbnkijodmdjhbjlgp` · **Version:** 2026.9.15.2 · **Manifest:** V3
- **CRX SHA-256:** `8b9903bc23c13b7861590116390142a0cd09b2a32fcf7364ab4c9500241669a7`
- Unpacked: `crx/unpacked/privacy_badger/` (175 files, 11 MB)

## Permissions
- `permissions`: alarms, **declarativeNetRequest**, privacy, scripting, storage, tabs,
  **webNavigation**, **webRequest**
- `host_permissions`: `<all_urls>`
- Background is an ES-module service worker (`js/background.js`).

**Mechanism — different from a filter-list blocker:** Privacy Badger has `webRequest` (observe, MV3)
+ `webNavigation` and **learns** third-party trackers heuristically (it watches which third-party
origins track you across first-party sites, then blocks/cookie-blocks them). Its static DNR
rulesets are therefore deliberately small.

## Content scripts (heuristic detectors, not scrapers)
- `fingerprinting.js`, `clobberstorage.js` on `<all_urls>` document_start (all_frames) — detect
  canvas fingerprinting / storage supercookies.
- `socialwidgets.js`, `supercookie.js` on `<all_urls>` document_idle.
- Site-specific first-party-tracking unwrappers for Facebook/Messenger and the full Google ccTLD
  list (`js/firstparties/*`).

## Static DNR rulesets (`data/dnr/*.json`, all enabled)
`dnt_policy` (Do-Not-Track compliant allowlist), `gen204` (Google `/gen_204` beacons),
`bypass_redirects` (Google redirect unwrapping), `ignore`. Small by design.

## Coverage of assistant domains
| domain | static hits |
|---|---|
| sider.ai / monica.im / getmerlin.in / foyer.work | **0** |
| google-analytics.com | 0 (**learned at runtime**, not static) |

**Reading:** Static coverage is 0 for everything of interest, but that **understates** Privacy
Badger because its blocking is dynamic. Whether it ends up blocking an assistant's GA/third-party
calls must be measured at **runtime** (Phase 4/5), after it has "learned." It is unlikely to touch
first-party assistant APIs (by design it does not block first-party domains). No bundled telemetry
(EFF).
