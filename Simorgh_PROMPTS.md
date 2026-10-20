# Simorgh — Windows Censorship-Circumvention Client

> Suggested name: **Simorgh** (Persian for "flight") — repo: `parvaz-windows`
> Alternatives: **Rahyab** (pathfinder) · **Parand** · **Simorgh Gate**
> Check that the name is available on GitHub before finalizing.

This file has three parts. Feed them to your IDE agent (Cursor / Windsurf / Claude Code / Copilot Agent) in this order:

1. **Prompt 1** — Build the UI (visuals only, mock data)
2. **Prompt 2** — Implement the logic and code
3. **Task Breakdown** — Phase-by-phase checklist with acceptance criteria

Working rule: give each prompt in a fresh chat/session, and after each phase run the app and test it before moving on.

---

## Architecture Overview (for reference)

- **UI:** Flutter Desktop (Windows), dark theme, RTL-capable (Persian default, English option)
- **Connection core:** sing-box (or Xray) as a sidecar process
- **Relay:** Cloudflare Worker deployed from inside the app via the Cloudflare API (no VPS needed)
- **Clean IP scanner:** runs the moment the user presses Connect, with live progress shown in the UI
- **AI diagnostics assistant:** the user provides an API key; redacted logs are analyzed and the reason the app failed to connect is shown in a console with copyable text
- **Debug Bundle:** a copyable output you paste straight into your IDE so the app can be patched and kept working over time

---

# PROMPT 1 — Build the UI

> Give this section to the IDE verbatim.

```text
ROLE
You are a senior Flutter desktop engineer and UI designer. Build ONLY the UI layer (no real networking, no real logic) of a Windows desktop app called "Parvaz".

GOAL
A clean, modern, dark-themed Windows app whose main purpose is: the user presses ONE big Connect button, the app automatically scans for clean Cloudflare IPs, shows that scanning LIVE, then connects. It also has an AI-assisted diagnostics console.

TECH CONSTRAINTS
- Flutter stable, target Windows desktop only.
- State management: GetX pattern (controllers + bindings + views) with a clean folder structure:
  lib/
    app/ (routes, bindings, theme)
    core/ (constants, utils, shared widgets)
    features/
      home/ (view, controller, widgets)
      scan/ (live scan panel widgets)
      relays/
      console/
      ai_settings/
      settings/
    models/
- Use mock data and fake timers/streams to simulate states. NO real network calls in this phase.
- Packages allowed: get, window_manager, tray_manager (stub only), google_fonts or a bundled font (Vazirmatn for Persian, Inter for English), flutter_animate (optional).
- Full RTL support. All user-facing strings live in a single localization layer (`strings.dart` or ARB files) with Persian (default) and English.
- Window: minimum size 960x640, custom draggable title bar, minimize and close-to-tray buttons.

DESIGN LANGUAGE
- Dark theme, deep navy/charcoal background, one vivid accent (electric cyan or lime), soft glow on active states, 16px rounded cards, generous spacing, subtle animations (200–300ms).
- Typography: proportional UI font as above. Monospace (JetBrains Mono / Cascadia Mono) for the console and IP addresses.
- Define all colors, spacing and radii in a single theme file (design tokens). No hardcoded colors inside widgets.

SCREENS (navigation rail on the leading side; mirrors automatically in RTL)
1) Home (main)
   - Huge circular Connect button in the center with states: Idle, Scanning, Connecting, Connected, Failed. Each state has a distinct color, icon and label.
   - Under it: a status line (current stage text), elapsed timer, and when connected: current IP, latency (ms), upload/download speed, session traffic.
   - Below the button: a "Live Scan Panel" card visible while scanning:
       * Stage stepper: Prepare -> Scan IPs -> Select best -> Build config -> Start core -> Verify connection
       * Progress bar + counters: tested / total, clean found, failed, current speed (IPs/sec)
       * A live-updating, virtualized table of IPs being tested: IP, latency, status chip (testing / clean / blocked / timeout). The best IP is highlighted and pinned on top.
       * A small live line chart of latency for the best candidates
       * Cancel button
2) Relays
   - List of Cloudflare relays as cards: name, domain, health dot, last latency, requests used today vs the 100k daily limit (progress bar), actions: test, edit, delete, set active.
   - "Add relay" button opening a dialog with two tabs: "Auto-deploy (API token)" and "Manual (paste config / link)".
3) Console / Diagnostics
   - Terminal-style panel, monospace, built with SelectionArea / SelectableText so ALL text is selectable and copyable.
   - Color-coded log levels (INFO / WARN / ERROR / AI).
   - Toolbar: "Copy all", "Copy last error", "Copy for IDE" (copies a structured Markdown debug bundle), "Analyze with AI", "Clear", log-level filter, search box, auto-scroll toggle.
   - A highlighted "AI Diagnosis" card above the log showing: Root cause, Evidence (log lines), Suggested fix, Confidence — each part with its own copy button.
4) AI Settings
   - Fields: Provider (OpenAI-compatible / custom), Base URL, API Key (obscured, with show/hide), Model name, "Test connection" button with a result chip, toggle "Auto-analyze on failure", toggle "Redact sensitive data before sending" (default ON), and a short privacy note.
5) Settings
   - Connection mode (System Proxy / TUN — TUN disabled with a "requires admin" hint), start with Windows, minimize to tray, auto-reconnect, scan settings (concurrency, timeout, max IPs, preferred ports), language, about/version, "Export debug bundle".

QUALITY BAR
- Split widgets into small reusable files; no file longer than 300 lines.
- Responsive across desktop window sizes.
- Every interactive widget has hover, focus and disabled states.
- Provide a `MockScanService` that emits a Stream of fake scan events so the Live Scan Panel animates realistically.
- Run `flutter analyze` and fix all warnings.

DELIVERABLE
A working Windows app that launches with all 5 screens navigable, and where the Home screen demonstrates the full fake flow: Idle -> Scanning (live table animating) -> Connecting -> Connected. Add a hidden debug menu button that forces the Failed state so the console and AI diagnosis card can be previewed.
Do not implement real logic. Stop after the UI is done and summarize the folder structure.
```

---

# PROMPT 2 — Logic and Code

> Give this to the IDE after you have approved the UI.

```text
ROLE
You are a senior Flutter/Dart and networking engineer. The UI of "Parvaz" (Windows, Flutter, GetX) already exists with mock services. Replace the mocks with real implementations, following the architecture and tasks below. Work task by task; after each task run analyze/tests and report.

NON-NEGOTIABLE PRINCIPLES
1. Every layer must be observable: all services write structured events to a central `LogService` (level, timestamp, component, message, error code, metadata).
2. Secrets (API keys, Cloudflare tokens, UUIDs, full configs) must NEVER be logged in plain text. Implement a `Redactor` used by LogService and by anything sent to the AI.
3. Store secrets through `get_x_storage_secure` and Windows DPAPI, never in plain files.
4. Every failure maps to a typed `FailureCode` (see below) so diagnostics are deterministic BEFORE the AI is called.
5. Code must be testable: services behind interfaces, dependencies injected via GetX bindings.

ARCHITECTURE (services)
- `CoreService` — downloads/verifies/launches sing-box as a sidecar process, builds the config JSON, supports System Proxy mode (set/restore Windows proxy via registry/WinINet), pipes core stdout/stderr into LogService, restarts on crash, restores proxy settings on exit/crash.
- `CloudflareDeployService` — using a user-supplied API token: validates the token, deploys the Worker script (bundled in /worker), creates a workers.dev route or custom domain, generates a UUID + random path, returns a `RelayConfig`. Handles API errors with typed failures (invalid token, quota, name taken, rate limit).
- `IpScannerService` — see "Scan algorithm".
- `HealthService` — after connect, probes through the proxy (e.g. generate_204 endpoints, DNS check) every N seconds; triggers auto-failover to the next best IP/relay.
- `ConfigUpdateService` — fetches updated configs and Cloudflare IP ranges from multiple fallback sources (GitHub raw, Gist, bundled). Verify hashes before applying.
- `LogService` — ring buffer (e.g. 5000 lines), stream for the UI, file persistence with rotation, structured JSON plus a human-readable view.
- `Redactor` — regex plus a registry of known secrets, masking tokens, UUIDs, API keys, the user's own IP and passwords in URLs.
- `DiagnosticsService` — see "Diagnostics".
- `AiClient` — OpenAI-compatible HTTP client (configurable base URL, API key, model), optional streaming, timeouts, retries, never blocks the UI.

CONNECT FLOW (state machine; emits events to the UI in real time)
Idle -> Preparing -> Scanning -> SelectingBest -> BuildingConfig -> StartingCore -> VerifyingConnection -> Connected
Any stage may transition to Failed(FailureCode, details). On Failed: automatically run DiagnosticsService, show the result in the Console, and if enabled, call the AI.

SCAN ALGORITHM (IpScannerService)
- Input: Cloudflare IPv4/IPv6 CIDR list (fetch from the official ips-v4 / ips-v6 endpoints, fall back to a bundled list), user-selected ports (default 443, 8443, 2053, 2083, 2087, 2096), target worker hostname (SNI/Host).
- Phase A (fast filter): randomly sample N IPs (default 300–1000) from the CIDRs; run with bounded concurrency (default 40) using Dart isolates or an async pool: TCP connect + TLS handshake with SNI = worker host, timeout 2–3s. Record handshake latency.
- Phase B (real test): take the top K (default 15) from Phase A and send a real HTTP request to the worker through each IP (resolve override), verifying an expected response (e.g. the worker health endpoint returns a known token). Measure latency 3 times and compute jitter and success rate.
- Phase C (rank): score = weighted(latency, jitter, success rate, previous-session success history). Pick the best; keep the top 5 as a failover list. Cache good IPs (with timestamps) for instant reuse next time; re-validate cached IPs first for a fast connect.
- Emit a `Stream<ScanEvent>` (types: started, ipTested, ipClean, ipFailed, phaseChanged, progress, bestChanged, finished, cancelled) that the Live Scan Panel renders in real time (tested/total, IPs/sec, per-IP status, best IP pinned).
- Support cancellation at any time (clean up sockets/isolates).

FAILURE CODES (extend as needed)
E_NO_INTERNET, E_DNS_FAIL, E_CF_RANGES_UNREACHABLE, E_ALL_IPS_BLOCKED, E_TLS_HANDSHAKE_RESET, E_SNI_BLOCKED, E_WORKER_404, E_WORKER_QUOTA_EXCEEDED, E_WORKER_BLOCKED_BY_CF, E_TOKEN_INVALID, E_CORE_MISSING, E_CORE_CRASH, E_CORE_CONFIG_INVALID, E_PORT_IN_USE, E_PROXY_SET_FAILED, E_AV_QUARANTINED_CORE, E_VERIFY_TIMEOUT, E_UNKNOWN.
Each code has: a short localized title, a plain explanation, and a list of deterministic suggested fixes.

DIAGNOSTICS (the "keep it working forever" loop)
- On failure, `DiagnosticsService` creates a `DebugBundle`:
  * app version, Windows version, connection mode, stage where it failed, FailureCode
  * last 200 redacted log lines + core stderr tail
  * scan summary (phase results, counts, best/failed IP stats; Cloudflare IPs are fine to include)
  * sanitized config structure (secrets replaced by <REDACTED>)
  * network checks: DNS resolve test, plain internet reachability, proxy settings state
- Step 1: rule-based analysis -> deterministic cause + fixes.
- Step 2 (if an API key is set and the feature is enabled): send the redacted DebugBundle to the AI with a strict system prompt requesting JSON: { root_cause, evidence[], suggested_fix, code_change_hint, confidence }. Parse safely; on parse failure show the raw text.
- The Console shows: rule-based result + AI diagnosis cards + raw logs; ALL selectable and copyable.
- The "Copy for IDE" button produces a Markdown block:
  ```
  ## Parvaz Debug Bundle
  - Version / OS / Mode / Stage / FailureCode
  ### Root cause (rule-based + AI)
  ### Evidence (log lines)
  ### Scan summary
  ### Sanitized config
  ### Task for IDE: "Fix the above issue. Identify the responsible file/service, propose a patch, add/adjust a test, and update the FailureCode mapping if needed."
  ```
  so the developer can paste it straight into the IDE to patch the app.

SECURITY & PRIVACY
- Redact before any external call; show the user exactly what will be sent (preview dialog, can be turned off).
- No telemetry. The AI call is made only with the user's own key.
- Verify the sha256 of downloaded core binaries; ship the hashes in the repo.
- Always restore Windows proxy settings on exit, on crash, and on next launch (crash-recovery flag).

TESTING
- Unit tests: Redactor, scan scoring, failure-code mapping, config builder, state machine transitions.
- Fake services for integration tests of the connect flow (simulate each FailureCode).
- `flutter test` and `flutter analyze` must be clean.

DELIVERY
Work in the order of the task list. After each task: summarize files changed, how to test manually, and any open risks.
```

---

# Task Breakdown

> Give each task to the IDE separately. After each task: run, test, commit.

## Phase 0 — Project Setup
- [ ] **T0.1** Create the repo, folder structure, `LICENSE` (MIT), initial `README`, `.gitignore`
  - *Acceptance:* the project runs on Windows and shows an empty window
- [ ] **T0.2** Run **Prompt 1** and complete the UI with mock data
  - *Acceptance:* all 5 screens navigable, the fake connect and failure flows visible, `flutter analyze` clean

## Phase 1 — Foundations
- [ ] **T1.1** `LogService` + `Redactor` + tests
  - *Acceptance:* live logs appear in the console; tokens and keys never appear in plain text
- [ ] **T1.2** `FailureCode` definitions with localized messages, explanations and fixes
- [ ] **T1.3** Secure storage (Credential Manager) for the Cloudflare token and AI key

## Phase 2 — Core and Connection
- [ ] **T2.1** `CoreService`: download, verify hash, launch sing-box, pipe stdout/stderr into LogService
  - *Acceptance:* with a manually tested config, a connection is established
- [ ] **T2.2** System Proxy mode with safe restore (including after a crash)
- [ ] **T2.3** Connection state machine wired to the UI

## Phase 3 — Live IP Scanner (core feature)
- [ ] **T3.1** Fetch Cloudflare ranges with a local fallback
- [ ] **T3.2** Phase A: fast TCP/TLS scan with configurable concurrency
- [ ] **T3.3** Phase B: real test through the Worker + jitter and success-rate calculation
- [ ] **T3.4** Phase C: scoring, cache of good IPs, failover list
- [ ] **T3.5** Stream `ScanEvent`s to the live panel (table, progress, IPs/sec, pinned best IP) and a cancel button
  - *Acceptance:* pressing Connect shows the scan live, step by step, and the best IP is selected at the end

## Phase 4 — Relay Without a VPS
- [ ] **T4.1** Worker template in `/worker` with a health endpoint
- [ ] **T4.2** `CloudflareDeployService`: token validation, deployment, UUID/random path generation
- [ ] **T4.3** Multi-relay management, daily usage display, health checks

## Phase 5 — Diagnostics and AI (core feature)
- [ ] **T5.1** `DiagnosticsService`: DebugBundle + rule-based analysis
- [ ] **T5.2** `AiClient` (OpenAI-compatible) + AI Settings screen + connection test
- [ ] **T5.3** Preview of data sent to the AI + "AI Diagnosis" card in the console
- [ ] **T5.4** Buttons: Copy all / Copy last error / **Copy for IDE** / Analyze with AI
  - *Acceptance:* when each `FailureCode` is simulated, the cause and fix appear in the console and are copyable

## Phase 6 — Resilience and Stability
- [ ] **T6.1** `HealthService` + automatic failover
- [ ] **T6.2** `ConfigUpdateService` with multiple fallback sources and hash verification
- [ ] **T6.3** Tray icon, start with Windows, auto-reconnect

## Phase 7 — Release
- [ ] **T7.1** Installer (Inno Setup) + Portable build + published file hashes
- [ ] **T7.2** Test on a clean Windows machine (no Flutter, no dev tools)
- [ ] **T7.3** README (English + Persian) with a demo GIF, a guide for getting a Cloudflare API token, and sections on privacy and risks
- [ ] **T7.4** Submit to the contest before the deadline (Oct 20, 11:59 PM IST), leaving a buffer

---

## Continuous Development Loop (after every failure)
1. A connection fails -> the console shows the cause
2. Press **Copy for IDE**
3. Paste into the IDE -> the IDE finds the responsible file/service and patches it
4. Add a new test for that `FailureCode` so the bug doesn't come back

## Important Notes
- Read the contest rules (or ask on Discord) to confirm this kind of project is accepted.
- Check Cloudflare Workers' terms of use regarding proxy usage; keep the architecture pluggable so other providers (Deno Deploy, etc.) can replace it.
- Antivirus software may flag the core executable; publish file hashes and explain this in the README.
- Assess your own legal and security risk, and choose the identity you publish the repo under deliberately.
