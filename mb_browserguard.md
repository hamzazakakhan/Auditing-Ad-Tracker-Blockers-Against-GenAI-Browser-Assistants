# Malwarebytes Browser Guard — static analysis

- **Store ID:** `ihcjicgdanjaechkgeegckofjjedodee` · **Version:** 3.3.7 · **Manifest:** V3
- **CRX SHA-256:** `d2da549805fdeb2052a4387d9bff7be3405127f22c6ec60c5c7b5b131f7a29fc`
- Unpacked: `crx/unpacked/mb_browserguard/` (599 files, 59 MB)
- **Hard rule reminder:** analysed only as a normally-installed extension. No Hubble credentials,
  JWTs, or related PoC are used or stored (cf. prior Malwarebytes RE kept separate in `~/mwb-re`).

## Permissions
- `permissions`: alarms, downloads, storage, tabs, **declarativeNetRequest**, unlimitedStorage,
  **webRequest**, contextMenus, **nativeMessaging**, activeTab, scripting, identity
- `optional_permissions`: clipboardRead, history, contentSettings, privacy
- `host_permissions`: `<all_urls>`
- `externally_connectable`: `https://my.malwarebytes.com/*`

**Risk read:** The broadest permission set of the blockers — `nativeMessaging` (can talk to a native
host app outside the browser sandbox), `downloads`, `identity`, optional `clipboardRead`/`history`.
`nativeMessaging` is noted **statically only** here; no native component is invoked by this project.

## Content scripts
- `content-scripts.js` on `http://*/*`,`https://*/*` document_start (all_frames) — the scanning hook.
- Site-specific: `content-oap-notification.js` (myaccount.google.com), `content-linkedin.js`.

## DNR rulesets (`db/*.json`) — note the default-off lists
| ruleset | enabled by default |
|---|---|
| `mbgc.mv3.whitelist_1`, `mbgc.arw`, `mbgc.mv3.always_allow_DNR` | ✅ |
| `mbgc.mv3.ads_1`, `ads_2`, `malware_1`, **`easylist_1`**, **`easyprivacy_1`** | ❌ **disabled** |

**Key point:** Browser Guard ships EasyList/EasyPrivacy/ads/malware rulesets but **disabled by
default** (toggled on via its own UI/logic at runtime). Out of the box it enforces mainly its
whitelist + Malwarebytes' own `arw` list, so its *default* ad/tracker blocking is lighter than the
bundle implies. Phase 5 should record whether the tested configuration has these enabled.

## Coverage of assistant domains
| domain | hits (easyprivacy_1, disabled) |
|---|---|
| sider.ai / monica.im / getmerlin.in / foyer.work | **0** |
| googletagmanager | 1 |

**Reading:** Even its (disabled) EasyPrivacy list does not cover assistant first-party domains. With
the list disabled by default, MB Browser Guard is unlikely to affect assistant traffic at all in a
default install — to be confirmed in Phase 4/5.

## For Phase 2b
- `nativeMessaging` host name + what the SW exchanges with it (static strings only).
- Its own telemetry endpoints (`my.malwarebytes.com`, `*.malwarebytes.com`) and what they receive.
