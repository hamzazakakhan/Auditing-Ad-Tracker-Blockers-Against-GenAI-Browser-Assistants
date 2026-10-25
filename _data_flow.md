# Phase 2b — cross-cutting data-flow (assistants)

Evidence is cited as `file @ offset` into the **unpacked** bundle (minified, single line, so byte
offset not line number). CRX SHA-256s in `crx/HASHES.md` pin the exact artifacts. Snippets were
extracted with `src/snippet.py` (read-only context windows).

## The common pattern (all three assistants)

```
  PAGE (canary DOM)
     │  read in the content script's ISOLATED WORLD (Phase 1 §c: full DOM, unmediatable)
     ▼
  CONTENT SCRIPT  ──(chrome.runtime.sendMessage {type, payload})──►  SERVICE WORKER
     │                                                                   │
     │ (content-script fetch() ALSO exists in all three bundles)         │ fetch() to first-party API
     ▼                                                                   ▼
  [possible page-origin egress — VISIBLE?]                         [chrome-extension origin egress — HIDDEN per §b]
```

**Why this matters for the research question:** the exfiltration-bearing request can leave by two
routes, and Chromium treats them differently (Phase 1 §b):
- **Service-worker `fetch()`** — initiator `chrome-extension://<assistant>` → another extension's
  DNR ruleset is **not evaluated** (`ruleset_manager.cc:629-639`). A blocker can't touch it.
- **Content-script `fetch()`** — may carry the *page* origin as initiator → *could* be visible to a
  blocker's rules. (Exact attribution is version-dependent; **resolved empirically in Phase 4** by
  reading the captured request's initiator. Not asserted from memory.)

Static analysis shows the **primary collection path relays to the background** (evidence below), i.e.
the hidden route, but all three *also* bundle `fetch()` inside content scripts. Phase 4 determines
which route carries the canary.

## Per-assistant collection evidence

### Monica — `content.js`
`content.js @ 18738155` returns the page-capture object:
```js
return { nodeContent: r?.content||"", fullText: document.body.innerText,
         images: n, meta:{ title: document.title||"", url: document.location.href } }
```
→ collects **full page text** + title + URL + images. Also `detectTextLang(document.body.innerText)`
(`@ 21324140`) runs on load (language detection over the whole page). Relays via
`chrome.runtime.sendMessage` (16×) to the SW; SW posts to `api.monica.im` (static literal
`api.monica.im/agent_v1`) and `*.butterfly-effect.dev`. `sendBeacon` used 3× (telemetry).

### Sider — `content-all.js`
`content-all.js @ 6004817` and `@ 6005073` build the capture object:
```js
{ type:"webpage", title:i, description:o, readableHtml:B_(u,…), html:document.documentElement.outerHTML,
  url:window.location.href, text:u, canSummarize:… }
```
→ ships the **entire page HTML** (`documentElement.outerHTML`) + readable text + URL. `getSelection`
used 160× (selection Q&A). Relays via `runtime.sendMessage`/`onMessage` (228 handlers) to SW; SW
posts to `sider.ai`, `ask.sider.ai`, telemetry to `event.sider.ai`. Uses `chrome.cookies` (1×) and
`WebSocket` (20×, streaming responses). MAIN-world `inject-xhr-hack.js`/`inject-json-hack.js` hook
page XHR/JSON on YouTube/Netflix.

### Merlin — `content-scripts/*` (WXT framework; `browser`/`chrome` alias)
- `main.js`: on load sends `{ type:"REFERRER_LOGGER", referrer: document.referrer }` to SW — passive
  referrer logging even without user action.
- `askMerlinSelection.js`: reads `getSelection().toString()` → sends `{ type:"ASK_MERLIN_SELECTION", … }`.
- `blog-summarizer.js`: page-content summarization path.
- SW (`background.js`) posts to `getmerlin.in` / `feedback.getmerlin.in`; Firebase auth via
  `identitytoolkit.googleapis.com`.
- **Third-party collector:** `giveFreely.js` (93 KB) runs on `<all_urls>` — an affiliate/shopping
  data-monetization SDK bundled into the assistant (static endpoint seen: `shop.app`; its telemetry
  hosts are built dynamically → capture in Phase 4). Distinct from Merlin's own AI backend.

## WASM / native
- **WASM:** only Sider — `mp4_muxer.wasm` (1 MB). `strings` confirm an **FFmpeg-derived MP4/AAC
  muxer** ("AAC encoder", "mov/mp4 format", ffmpeg-devel help URL); supports the tab/screen
  recording feature (`tabCapture`, `record-background.js`). **No network/host strings** → not an
  exfiltration component.
- **Native binaries / bundled executables:** **none found** in any of the six extensions
  (`find … -iregex '.*\.(exe|dll|so|dylib|node|bin)$'` → empty). MB Browser Guard declares
  `nativeMessaging` but ships **no** host binary in the CRX (the host is part of the separate
  Malwarebytes desktop product; out of scope — static note only).

## Correlation plan (Phase 4)
Every captured canary-bearing request must map to one of the collection functions above; any
collection function that never fires in capture will be noted as a non-exercised path.
