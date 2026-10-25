# Can Privacy Extensions Protect You From Other Extensions?

### Auditing Ad/Tracker Blockers Against GenAI Browser Assistants

![Course](https://img.shields.io/badge/course-CY321%20Secure%20Software%20Design-1c3e6e)
![Status](https://img.shields.io/badge/status-static%20analysis%20complete-orange)
![Platform](https://img.shields.io/badge/browser-Chrome%20139%20(MV3)-blue)

| | |
|---|---|
| **Student** | Hamza (Reg. No. 2024213) |
| **Course** | CY321 Secure Software Design |
| **Project ID** | 32104 |

---

## Table of Contents

- [Summary](#summary)
- [Research Question](#research-question)
- [Novel Security Problem Addressed](#novel-security-problem-addressed)
- [Scope and Targets](#scope-and-targets)
- [Methodology](#methodology)
- [Status](#status)
- [Expected Impact](#expected-impact)
- [Reference](#reference)

---

## Summary

GenAI browser assistants such as Sider, Monica, Merlin, MaxAI, Perplexity, Harpa, TinaMind, Copilot and ChatGPT for Google run as browser extensions with deep DOM access. They can read and transmit full webpage content, including sensitive data such as Social Security numbers, medical records and academic grades.

Most of this data goes to the assistant's own first-party servers. Some assistants also share chat or user identifiers with third parties such as Google Analytics and Mixpanel (USENIX Security 2025, *"Big Help or Big Brother?"*).

That study used vanilla Chrome with no privacy tooling installed. This project addresses the question it left open.

## Research Question

> Can a privacy or ad-blocking extension running alongside a GenAI assistant meaningfully reduce its data collection, or is the collection built into the assistant's own first-party design in a way no blocker can touch?

## Novel Security Problem Addressed

Existing research documents that GenAI browser assistants exfiltrate sensitive page content and identifiers. It has not evaluated whether commonly deployed privacy tooling can mitigate this risk.

This leaves a gap. Users may believe their privacy extensions protect them from assistant-based data collection. In practice the collection may be architecturally immune to blocking, for example same-origin requests that look identical to legitimate assistant functionality.

To our knowledge, this project is the first to empirically test whether privacy extensions protect against a different, more privileged class of extension.

## Scope and Targets

Three GenAI assistants are each tested against three privacy/blocking extensions in a controlled environment.

| Role | Extension | Version |
|---|---|---|
| Assistant | Sider | 5.35.1 |
| Assistant | Monica | 9.0.23 |
| Assistant | Merlin | 8.3.0 |
| Blocker | uBlock Origin Lite | 2026.1018.2229 |
| Blocker | Privacy Badger | 2026.9.15.2 |
| Blocker | Malwarebytes Browser Guard | 3.3.7 |

All targets are Manifest V3 extensions tested on Chrome 139. Classic uBlock Origin is not available for MV3 Chrome, so uBlock Origin Lite is used instead.

## Methodology

1. **Source study.** Read how Chromium routes extension requests and which requests a blocker's `declarativeNetRequest` rules can see.
2. **Static analysis.** Unpack each CRX package and review permissions, content scripts, rulesets and backend endpoints.
3. **Secret triage.** Scan the packages for hardcoded credentials and classify every candidate.
4. **Instrumented capture** *(planned)*. Run browser sessions against canary pages with synthetic sensitive data. Capture traffic with mitmproxy.
5. **Experiment matrix** *(planned)*. Measure each assistant with no blocker (baseline) and with each blocker enabled: 3 assistants × 4 conditions × 3 tasks × 3 repetitions = 108 runs.
6. **Direct blocker test** *(planned)*. Use a test extension with a rule that blocks the assistants' domains, to check whether any assistant request is blockable at all.

First-party (the assistant's own servers) and third-party (analytics and tracking) traffic are measured separately. Blockers are more likely to affect third-party requests than an assistant's core data pipeline.

## Status

| Phase | Work | Status |
|---|---|---|
| 1 | Chromium source study | Done |
| 2 | Static analysis of six extensions | Done |
| 2b | Reverse engineering and secret triage | Done |
| 3 | Canary test pages | Planned |
| 4 | Capture harness | Planned |
| 5 | Experiment matrix (108 runs) | Planned |
| 6 | Direct blocker test | Planned |
| 7 | Analysis and final report | Planned |

### Findings so far (static and source-level)

- A blocker's declarative ruleset is not evaluated for requests initiated by another extension's `chrome-extension://` origin. A service-worker call to an assistant's own API is therefore outside a blocker's reach.
- Sider ships the full document HTML. Monica sends the full page text. Merlin bundles a third-party affiliate SDK.
- No blocker ruleset names any assistant's first-party domain.
- Secret scan: 123 candidates, 0 confirmed hardcoded credentials.

### Hypotheses (not yet tested)

- **H1.** Blockers will not reduce first-party collection.
- **H2.** Blockers can at most reduce third-party traffic, and only when it is visible to their rules.
- **H3.** Browser Guard, with its tracker lists disabled by default, will have little effect.
- **H4.** Privacy Badger's effect depends on how much it has learned.

### Limitations

- The analysis so far is static, so counts may miss dynamically built hosts.
- The Chromium checkout is not yet pinned to the tag matching Chrome 139.
- Three assistants and three blockers form a small sample.
- Pattern-based secret scanning can miss encoded values.

## Expected Impact

- **Users and organizations:** evidence-based guidance on whether ad/tracker blockers are enough when using GenAI browser assistants, or whether further controls are needed (assistant allowlisting, DLP policies, or avoiding certain assistants).
- **Extension developers:** a view of which collection patterns are currently blockable and which need new detection approaches.
- **Policymakers and enterprise security teams:** a reproducible methodology for auditing third-party AI browser tooling before deployment.

## Reference

Vekaria, Y., Canino, A. L., Levitsky, J., Ciechonski, A., Callejo, P., Mandalari, A. M., and Shafiq, Z. *Big Help or Big Brother? Auditing Tracking, Profiling, and Personalization in Generative AI Assistants.* 34th USENIX Security Symposium, 2025, pp. 8115–8134.

---

*Draft in progress. The full report is maintained separately.*
