# uBlock Origin Lite — RE findings (Phase 2b)

- v2026.1018.2229 · CRX SHA-256 `559d10ef7dcb96bc4e812de6b3ff0c2e6c7abca578324d8d7afd7d8cf78a6dd7`

## Mechanism
- **DNR-only** (no `webRequest` permission). No manifest content scripts; cosmetic filtering injected
  on demand via `scripting`. Enforcement limited to the DNR action set (Phase 1 §a).

## Exfiltration check
- Page-content reads (`body.innerText`/`outerHTML`): **0**.
- `fetch(` ×14 — internal (loads its own packaged rulesets/resources). **No telemetry host** found
  (no analytics/third-party egress). Consistent with a privacy-respecting open-source blocker.

## Secrets
- 55 gitleaks hits are **filter-list entries** inside bundled rulesets, not credentials.

## Role in the experiment
Acts purely as a DNR blocker. Relevant finding (Phase 2): lists Google Analytics/GTM but **none** of
the assistant first-party domains, and (Phase 1 §b) cannot evaluate rules against another extension's
SW-initiated requests. Expected to block assistant GA *iff* that request is visible — the Phase 4
test variable.
