# uBlock Origin Lite — static analysis

- **Store ID:** `ddkjiahejlhfcafbddmgiahcphecmpfh` · **Version:** 2026.1018.2229 · **Manifest:** V3
- **CRX SHA-256:** `559d10ef7dcb96bc4e812de6b3ff0c2e6c7abca578324d8d7afd7d8cf78a6dd7`
- Unpacked: `crx/unpacked/ubo_lite/` (929 files, 35 MB)
- **This is the uBO build that actually installs on Chrome 139.** Classic MV2 uBO is not served
  (HTTP 204 — `crx/HASHES.md`).

## Permissions
- `permissions`: activeTab, alarms, **declarativeNetRequest**, offscreen, scripting, storage,
  unlimitedStorage, userScripts
- `host_permissions`: `<all_urls>` · **No `webRequest` permission at all.**
- No content scripts declared in the manifest (cosmetic filtering is injected via `scripting` on
  demand, not blanket observation).

**Mechanism:** Pure **declarativeNetRequest**. Blocking is limited to the DNR action set
(`BLOCK/REDIRECT/MODIFY_HEADERS/…`, Phase 1 §a). It cannot run arbitrary JS blocking logic or read
response bodies, and — critically for this project — its rulesets are **not evaluated against
requests initiated by another extension's service worker** (Phase 1 §b).

## Rulesets (`rulesets/main/*.json`, 56 files)
- **Enabled by default:** `ublock-filters`, `easylist`, **`easyprivacy`**, `pgl` (peter lowe),
  `ublock-badware`, `urlhaus-full`.
- Disabled by default: annoyances-*, regional lists (deu/fra/rus/…), experimental.

## Coverage of assistant domains (enabled lists)
| domain | hits |
|---|---|
| sider.ai / monica.im / getmerlin.in / foyer.work | **0** |
| google-analytics.com | 29 |
| googletagmanager | 45 |

**Reading:** uBO Lite can match the assistants' **Google Analytics** traffic but lists **none** of
their first-party API domains. Whether it can act on the GA request depends on request visibility
(Phase 1 §b; measured in Phase 4). No bundled telemetry (it's a blocker; its "analytics" string hits
are filter-list entries, not its own calls).
