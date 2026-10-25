# Phase 1 — Chromium source study (why a blocker can / cannot see an assistant's traffic)

**Method:** read-only. Sparse, shallow, blobless clone of `chromium/src` at `~/chromium-src`
(paths: `extensions/`, `chrome/browser/extensions/`). No build. Every claim below is tied to a
file:line in that checkout, or marked **UNVERIFIED (experiment)** where it is left for Phase 4.
Nothing here is stated from memory.

> Why this phase exists: Phase 4–6 will show *that* certain assistant requests are not blocked.
> This phase explains *why*, grounded in the browser's own code.

## Clone provenance
- Repo: `https://chromium.googlesource.com/chromium/src`
- HEAD commit: **`a559af362c7f4b9fb27e41efdf73b5d15ea30401`** (committed 2026-10-19)
- Checkout date: 2026-10-19
- Sparse paths present: `extensions`, `chrome/browser/extensions`
  (DNR lives under `extensions/browser/api/declarative_net_request/` and
  `extensions/common/api/declarative_net_request/` on this tree, not `components/`.)

All paths below are relative to `~/chromium-src`.

---

## a. How webRequest and DNR intercept requests; MV2 vs MV3

### Request interception point (shared plumbing)
Network requests for a tab are routed through an extensions proxying URL-loader factory. The
`OnBeforeRequest` stage runs the webRequest event pipeline:
- `extensions/browser/api/web_request/web_request_proxying_url_loader_factory.cc:343` — the proxy
  calls `...->OnBeforeRequest(browser_context_, &info_, ...)`; `state_on_error =
  State::kRejectedByOnBeforeRequest` (`:327`). Dedicated proxies also exist for WebSocket and
  WebTransport (`web_request_proxying_websocket.cc`, `web_request_proxying_webtransport.cc`) — so
  `ws://`/`wss://` are in scope for both the API and our Phase-4 capture.

### webRequest (observe vs block)
- `webRequest` (observe-only) is available to **both** MV2 and MV3 — no `max_manifest_version`:
  `extensions/common/api/_permission_features.json:859-863`.
- A **blocking** listener additionally requires the `webRequestBlocking` API permission:
  `extensions/browser/api/web_request/web_request_api.cc:574-596` — if the listener's
  `extra_info_spec` has `BLOCKING | ASYNC_BLOCKING` and the extension lacks
  `APIPermissionID::kWebRequestBlocking`, the registration is rejected with a console error
  (`kBlockingPermissionRequired`). (Same gate on the second listener path at `:1397-1413`.)

### declarativeNetRequest (MV3 declarative rules)
- Evaluation entry points: `extensions/browser/api/declarative_net_request/ruleset_manager.cc` —
  `EvaluateBeforeRequest()` (`:192`), `EvaluateRequestInternal()` (`:466`), which calls
  `GetAction()` (`:350-415`).
- Action types a rule may produce: `BLOCK`, `COLLAPSE`, `REDIRECT`, `UPGRADE`, `ALLOW`,
  `ALLOW_ALL_REQUESTS`, `MODIFY_HEADERS` (`ruleset_manager.cc:366-377`). There is **no action that
  returns request/response *contents* to the extension** — DNR is match-and-act only, never
  "read the body and decide in JS."

### The decisive MV2 → MV3 change
- `webRequestBlocking` is **`max_manifest_version: 2`** for normal extensions, and only allowed at
  `min_manifest_version: 3` when `"location": "policy"` (enterprise-force-installed):
  `extensions/common/api/_permission_features.json:870-879`.
- **Consequence:** a Web-Store-installed MV3 blocker *cannot* cancel/redirect a request via
  webRequest. It may still *observe* (non-blocking), but to actually block it must use DNR, whose
  power is limited to the declarative action set above.

| Capability | MV2 webRequest | MV3 DNR |
|---|---|---|
| Observe request metadata | ✅ | ✅ (webRequest observe still allowed in MV3) |
| Cancel / redirect in arbitrary JS | ✅ (`webRequestBlocking`) | ❌ (removed for store extensions) |
| Read response **body** to decide | ✅ (async blocking) | ❌ (no such action) |
| Block/redirect via static declarative rules | n/a | ✅ (`BLOCK`/`REDIRECT`/`MODIFY_HEADERS`/…) |
| Rule count / runtime flexibility | unlimited JS | bounded, declarative |

Source basis: `_permission_features.json:859-879`, `web_request_api.cc:574-596`,
`ruleset_manager.cc:350-415`.

---

## b. Is one extension's SW/content-script traffic visible to another extension's blocking rules?

**This is the crux of the research question.** Answer from source: **generally no**, for the path an
assistant actually uses (service-worker → first-party API).

### DNR explicitly skips other extensions' requests
`extensions/browser/api/declarative_net_request/ruleset_manager.cc:618-640`
(`ShouldEvaluateRulesetForRequest`):
> "Extensions should not generally have access to non-main-frame requests initiated by other
> extensions…"

The check (`:629-639`): if `--extensions-on-chrome-urls` is **not** set (default), the request has
an `initiator`, and the request type is **not** `MAIN_FRAME`, it takes the initiator's
precursor tuple; if `initiator_precursor.scheme() == chrome-extension` **and**
`initiator_precursor.host() != ruleset.extension_id`, it returns `false` → **blocker B's ruleset is
never evaluated against a request initiated by assistant A.**

### chrome-extension:// requests are exempt entirely
`ruleset_manager.cc:603-605` — requests on the `chrome-extension` scheme are not evaluated
(an extension can't even DNR-modify its own packaged resources).

### webRequest has the parallel gate
`extensions/browser/api/web_request/web_request_permissions.cc:257-329` (`HideRequest`) hides
sensitive/other-origin requests; `ruleset_manager.cc:597` `DCHECK`s that `HideRequest` already
filtered before DNR runs. Non-web-scheme URLs are hidden up front (`web_request_permissions.cc:260`).

### Cross-extension priority (when rules *do* both apply, e.g. ordinary page sub-resources)
`ruleset_manager.cc:383-385, 409-411` — across extensions, more recently installed extensions win
ties; `BLOCK/COLLAPSE` (prio 3) > `REDIRECT/UPGRADE` (2) > `ALLOW` (1).

**Conclusion (b):** For the request that carries the exfiltrated DOM — an assistant's **service
worker** `fetch()` to its own backend, whose initiator origin is `chrome-extension://<assistant>`
and whose type is not a main-frame navigation — a co-installed blocker's DNR rules are **not
evaluated at all** (`:629-639`), and MV3 denies it blocking webRequest anyway (§a). The blocker is
architecturally out of the loop.

> **UNVERIFIED (experiment, Phase 4):** the exact `initiator` attribution for (i) a service-worker
> `fetch` vs (ii) a `fetch` issued from a content script's isolated world (which may carry the
> *page* origin as initiator and therefore be visible to blockers). Assistants typically relay DOM
> from content script → background via `chrome.runtime.sendMessage`, then the SW makes the network
> call — putting it on the hidden path. Phase 2b (static) + Phase 4 (dynamic) will confirm which
> path each assistant uses.

---

## c. Content-script isolated worlds: assistant DOM access vs what a blocker can mediate

### Content scripts run in a per-host *isolated world*, same DOM
`extensions/renderer/script_injection.cc:336-352` — for `ExecutionWorld::kIsolated` /
`kUserScript`, the Blink world id comes from
`IsolatedWorldManager::GetOrCreateIsolatedWorldForHost(...)`; only `kMain` uses
`blink::kMainDOMWorldId`. The script is then executed on the frame via
`render_frame_->GetWebFrame()->RequestExecuteScript(blink_world_id, ...)` (`:363`) — i.e. a
**separate JS/V8 world but the same `document`/DOM**.

### Each extension gets its *own* isolated world
`extensions/renderer/isolated_world_manager.cc:131-162` — `GetOrCreateIsolatedWorldForHost` assigns
a fresh `blink_world_id` per host id (`:144-162`), storing per-world `host_id`, `security_origin`
(`:93`), `url`, `name`. So assistant A and blocker B occupy **different** isolated worlds.

**Conclusion (c):** An assistant content script in its isolated world has full synchronous read
access to the page DOM (`document.body.innerText`, `innerHTML`, form fields). A blocker extension
lives in a *different* isolated world; it can neither see A's JS state nor intercept A's DOM reads —
**a DOM read is an in-renderer JS operation with no network event and no cross-extension hook.**
There is simply no interception point for "extension A read the page text." A blocker can only act
on *network* egress (webRequest/DNR), which is exactly the path §a/§b shows it cannot reach for
SW-origin first-party calls.

---

## d. Permission model: host permissions, `<all_urls>`, activeTab → page-content access

`extensions/common/permissions/permissions_data.cc`:
- **Host (explicit) permissions / `<all_urls>`** feed `explicit_hosts()`; page access is
  `GetPageAccess()` → `CanRunOnPage(... explicit_hosts() ...)` (`:427-439`), surfaced by
  `CanAccessPage()` (`:417-424`). These grant cross-origin `fetch`/XHR and webRequest observation
  scope. `<all_urls>` is the meta-pattern `URLPattern::kAllUrlsPattern` (`url_pattern.cc:28`).
- **Content-script injection** is gated by `scriptable_hosts()`:
  `GetContentScriptAccess()` → `CanRunOnPage(... scriptable_hosts() ...)` (`:451-463`),
  `CanRunContentScriptOnPage()` (`:441-449`). A match here is what lets the assistant's content
  script run (and thus read the DOM, §c).
- **activeTab** is modelled as *tab-specific* permissions: every accessor pulls
  `GetTabSpecificPermissions(tab_id)` and unions it in (`:433`, `:457`). So activeTab grants
  temporary host access to the one active tab on user invocation, without a broad host grant.
- **Screenshot/`captureVisibleTab`** path `CanCaptureVisiblePage()` (`:492-567`) is itself gated on
  `<all_urls>` / activeTab / `GetPageAccess()` (`:549-556`) — relevant because some assistants
  screenshot the page as an alternative to DOM scraping.

**Conclusion (d):** The page-content access an assistant needs is granted *declaratively at install*
via `content_scripts` matches + host permissions (or per-use via activeTab). Once granted, the
isolated-world content script reads the DOM directly; the permission system has **no per-field or
per-read mediation**, and nothing lets a second extension interpose.

---

## Synthesis — the research question, answered mechanically

A GenAI assistant's data-collection path is typically:
1. **Content script** (isolated world, §c) reads page DOM — full access, no mediation possible.
2. Relays it to its **service worker** via `chrome.runtime.sendMessage` (intra-extension IPC, not a
   web request — invisible to any blocker).
3. Service worker `fetch()`s the assistant's **own first-party API** over HTTPS.

A co-installed ad/tracker blocker fails to reduce this for **two independent architectural reasons**:
- **It never sees the request.** The egress is a non-main-frame request with a
  `chrome-extension://<assistant>` initiator, so other extensions' DNR rulesets are not evaluated
  (`ruleset_manager.cc:629-639`), and MV3 forbids blocking webRequest (`_permission_features.json:870-879`).
- **Even if it saw it, it wouldn't match.** The destination is the assistant's *first-party* domain,
  not a known ad/tracker host in the filter lists (to be confirmed per-blocker in Phase 2).

And the DOM read in step 1 has no network footprint at all, so no network-layer blocker can touch
it. This is the basis for the hypothesis that the collection is **architecturally out of a blocker's
reach**, which Phase 4–6 will test empirically.

---

## Unverified / left for experiment (Phase 2b static, Phase 4 dynamic)
1. `initiator` attribution for SW `fetch` vs content-script-world `fetch` (§b caveat) — directly
   testable; determines the only scenario where a blocker *could* see assistant egress.
2. Whether each assistant (Sider/Monica/Merlin) actually relays via SW vs sends from the content
   script — Phase 2b code reading + Phase 4 capture.
3. Whether any blocker's filter list / DNR ruleset contains the assistants' first-party API domains
   — Phase 2 ruleset extraction.
