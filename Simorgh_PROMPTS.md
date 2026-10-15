# Parvaz (پرواز) — Windows Censorship-Circumvention Client

> نام پیشنهادی: **Parvaz (پرواز)** — ریپو: `parvaz-windows`
> نام‌های جایگزین: **Rahyab (راهیاب)** · **Parand (پرند)** · **Simorgh Gate**
> قبل از انتخاب نهایی، آزاد بودن نام روی GitHub و pub.dev را چک کن.

این فایل سه بخش دارد که به ترتیب به IDE (Cursor / Windsurf / Claude Code / Copilot Agent) بده:

1. **Prompt 1** — ساخت UI (فقط ظاهر، با داده‌ی نمایشی)
2. **Prompt 2** — نوشتن منطق و کد
3. **تسک‌بندی** — چک‌لیست مرحله‌به‌مرحله با معیار پذیرش

قانون کار: هر Prompt را در یک چت/سشن جدید بده و بعد از اتمام هر مرحله، برنامه را اجرا و تست کن.

---

## معماری کلی (برای مرجع)

- **UI:** Flutter Desktop (Windows) — RTL فارسی، تم تیره
- **هسته‌ی اتصال:** sing-box (یا Xray) به‌عنوان sidecar process
- **رله:** Cloudflare Worker که از داخل برنامه با API کلودفلر دیپلوی می‌شود (بدون VPS)
- **اسکنر IP تمیز:** اجرا در لحظه‌ی زدن دکمه‌ی اتصال، با نمایش زنده‌ی پیشرفت
- **دستیار عیب‌یابی AI:** کاربر API key می‌دهد؛ لاگ‌ها (پاک‌سازی‌شده) تحلیل می‌شوند و علت عدم اتصال در کنسول قابل‌کپی نمایش داده می‌شود
- **Debug Bundle:** خروجی قابل‌کپی که مستقیم به IDE داده می‌شود تا برنامه هر بار اصلاح شود

---

# PROMPT 1 — ساخت UI

> این بخش را عیناً به IDE بده.

```text
ROLE
You are a senior Flutter desktop engineer and UI designer. Build ONLY the UI layer (no real networking, no real logic) of a Windows desktop app called "Parvaz".

GOAL
A clean, modern, dark-themed Persian (RTL) Windows app whose main purpose is: the user presses ONE big Connect button, the app automatically scans for clean Cloudflare IPs, shows that scanning LIVE, then connects. It also has an AI-assisted diagnostics console.

TECH CONSTRAINTS
- Flutter stable, target Windows desktop only.
- State management: GetX pattern (controllers + bindings + views) with a clean folder structure:
  lib/
    app/ (routes, bindings, theme)
    core/ (constants, utils, widgets shared)
    features/
      home/ (view, controller, widgets)
      scan/ (live scan panel widgets)
      relays/
      console/
      ai_settings/
      settings/
    models/
- Use mock data and fake timers/streams to simulate states. NO real network calls in this phase.
- Packages allowed: get, window_manager, tray_manager (stub only), google_fonts or a bundled Persian font (Vazirmatn), flutter_animate (optional).
- Full RTL, Persian strings stored in a single `strings.dart` (easy to localize later).
- Window: min size 960x640, custom title bar (draggable), minimize/close-to-tray buttons.

DESIGN LANGUAGE
- Dark theme, deep navy/charcoal background, one vivid accent (electric cyan or lime), soft glow on active states, 16px rounded cards, generous spacing, subtle animations (200–300ms).
- Typography: Vazirmatn. Monospace (e.g. JetBrains Mono / Cascadia Mono) for console and IP addresses.
- Define all colors/spacing/radius in a single theme file (design tokens). No hardcoded colors in widgets.

SCREENS (left/right nav rail — right side because RTL)
1) Home (main)
   - Huge circular Connect button in the center with states: Idle, Scanning, Connecting, Connected, Failed. Each state has distinct color, icon, and label (Persian).
   - Under it: status line (current stage text), elapsed timer, and when connected: current IP, latency (ms), up/down speed, session traffic.
   - Below the button: a "Live Scan Panel" card that is visible while scanning:
       * Stage stepper: آماده‌سازی → اسکن IP → انتخاب بهترین → ساخت کانفیگ → اجرای هسته → تست اتصال
       * Progress bar + counters: tested / total, found clean, failed, current speed (IPs/sec)
       * A live-updating table (virtualized list) of IPs being tested: IP, latency, status chip (testing / clean / blocked / timeout), with the best IP highlighted and pinned on top
       * A small live line chart of latency of the best candidates
       * Cancel button
2) Relays (رله‌ها)
   - List of Cloudflare relays (cards): name, domain, health dot, last latency, requests used today vs 100k limit (progress), actions: test, edit, delete, set active.
   - "Add relay" button opening a dialog with two tabs: "Auto-deploy (API token)" and "Manual (paste config / link)".
3) Console / Diagnostics (کنسول عیب‌یابی)
   - Terminal-style panel, monospace, with SelectableText / SelectionArea so ALL text is selectable and copyable.
   - Color-coded log levels (INFO / WARN / ERROR / AI).
   - Toolbar: "Copy all", "Copy last error", "Copy for IDE" (copies a structured Markdown debug bundle), "Analyze with AI", "Clear", log level filter, search box, auto-scroll toggle.
   - A highlighted "AI Diagnosis" card above the log: shows Root cause, Evidence (log lines), Suggested fix, Confidence — each part copyable with its own copy button.
4) AI Settings (تنظیمات هوش مصنوعی)
   - Fields: Provider (OpenAI-compatible / custom), Base URL, API Key (obscured with show/hide), Model name, "Test connection" button with result chip, toggle "Auto-analyze on failure", toggle "Redact sensitive data before sending" (default ON), and a note on privacy.
5) Settings
   - Connection mode (System Proxy / TUN — TUN disabled with "requires admin" hint), start with Windows, minimize to tray, auto-reconnect, scan settings (concurrency, timeout, max IPs, preferred ports), language, about/version, "Export debug bundle".

QUALITY BAR
- All widgets split into small reusable files; no file > 300 lines.
- Responsive within desktop sizes.
- Every interactive widget has hover + focus + disabled states.
- Provide a `MockScanService` that emits a Stream of fake scan events so the Live Scan Panel animates realistically.
- Run `flutter analyze` and fix all warnings.

DELIVERABLE
Working Windows app launching with all 5 screens navigable and the Home screen demonstrating the full fake flow: Idle → Scanning (live table animating) → Connecting → Connected (and a button in debug menu to force Failed state to preview the console + AI diagnosis card).
Do not implement real logic. Stop after UI is done and summarize the folder structure.
```

---

# PROMPT 2 — منطق و کد

> بعد از تأیید UI، این را به IDE بده.

```text
ROLE
You are a senior Flutter/Dart + networking engineer. The UI of "Parvaz" (Windows, Flutter, GetX) already exists with mock services. Replace mocks with real implementations, following the architecture and tasks below. Work task by task; after each task run analyze/tests and report.

NON-NEGOTIABLE PRINCIPLES
1. Every layer must be observable: all services write structured events to a central `LogService` (level, timestamp, component, message, error code, metadata).
2. Secrets (API keys, Cloudflare tokens, UUIDs, full configs) must NEVER be logged in plain text. Implement a `Redactor` used by LogService and by anything sent to the AI.
3. Store secrets in Windows Credential Manager (flutter_secure_storage), never in plain files.
4. Every failure must map to a typed `FailureCode` (see below) so diagnostics are deterministic BEFORE the AI is even called.
5. Code must be testable: services behind interfaces, dependencies injected via GetX bindings.

ARCHITECTURE (services)
- `CoreService` — downloads/verifies/launches sing-box as a sidecar process, builds config JSON, supports System Proxy mode (set/restore Windows proxy via registry/WinINet), exposes core stdout/stderr as a stream into LogService, restarts on crash, restores proxy settings on exit/crash.
- `CloudflareDeployService` — using a user-supplied API token: validates token, deploys the Worker script (bundled in /worker), creates a workers.dev route or custom domain, generates UUID + random path, returns a `RelayConfig`. Handles API errors with typed failures (invalid token, quota, name taken, rate limit).
- `IpScannerService` — see "Scan algorithm".
- `HealthService` — after connect, probes through the proxy (e.g. generate_204 endpoints, DNS check) every N seconds; triggers auto-failover to next best IP/relay.
- `ConfigUpdateService` — fetches signed/hashed updated configs & Cloudflare IP ranges from multiple fallback sources (GitHub raw, Gist, bundled). Verify hash before applying.
- `LogService` — ring buffer (e.g. 5000 lines), stream for UI, file persistence with rotation, structured JSON + human-readable view.
- `Redactor` — regex + known-secret registry masking (tokens, UUIDs, API keys, IP of user, passwords in URLs).
- `DiagnosticsService` — see "Diagnostics".
- `AiClient` — OpenAI-compatible HTTP client (configurable base URL, API key, model), streaming optional, timeouts, retries, never blocks UI.

CONNECT FLOW (state machine, emits events to UI in real time)
Idle → Preparing → Scanning → SelectingBest → BuildingConfig → StartingCore → VerifyingConnection → Connected
Any stage may transition to Failed(FailureCode, details). On Failed: auto-run DiagnosticsService, show result in Console, and if enabled, call AI.

SCAN ALGORITHM (IpScannerService)
- Input: Cloudflare IPv4/IPv6 CIDR list (fetch from official ips-v4/ips-v6 endpoints; fall back to bundled list), user-selected ports (default 443, 8443, 2053, 2083, 2087, 2096), target worker hostname (SNI/Host).
- Phase A (fast filter): randomly sample N IPs (default 300–1000) from CIDRs; run with bounded concurrency (default 40) using Dart isolates or async pool: TCP connect + TLS handshake with SNI = worker host, timeout 2–3s. Record handshake latency.
- Phase B (real test): top K (default 15) from Phase A → send a real HTTP request to the worker through that IP (resolve override) and verify expected response (e.g. worker health endpoint returns a known token). Measure latency x3 and compute jitter + success rate.
- Phase C (rank): score = weighted(latency, jitter, success rate, previous-session success history). Pick best; keep top 5 as failover list. Cache good IPs (with timestamp) for instant reuse next time; re-validate cached IPs first for fast connect.
- Emit a `Stream<ScanEvent>` (type: started, ipTested, ipClean, ipFailed, phaseChanged, progress, bestChanged, finished, cancelled) that the Live Scan Panel renders in real time (tested/total, IPs/sec, per-IP status, best IP pinned).
- Support cancel at any time (clean up sockets/isolates).

FAILURE CODES (extend as needed)
E_NO_INTERNET, E_DNS_FAIL, E_CF_RANGES_UNREACHABLE, E_ALL_IPS_BLOCKED, E_TLS_HANDSHAKE_RESET, E_SNI_BLOCKED, E_WORKER_404, E_WORKER_QUOTA_EXCEEDED, E_WORKER_BLOCKED_BY_CF, E_TOKEN_INVALID, E_CORE_MISSING, E_CORE_CRASH, E_CORE_CONFIG_INVALID, E_PORT_IN_USE, E_PROXY_SET_FAILED, E_AV_QUARANTINED_CORE, E_VERIFY_TIMEOUT, E_UNKNOWN.
Each code has: short Persian title, plain explanation, and a list of deterministic suggested fixes.

DIAGNOSTICS (the "make it work forever" loop)
- On failure, `DiagnosticsService` creates a `DebugBundle`:
  * app version, Windows version, connection mode, stage where it failed, FailureCode
  * last 200 redacted log lines + core stderr tail
  * scan summary (phase results, counts, best/failed IP stats — IPs of Cloudflare are fine to include)
  * sanitized config structure (secrets replaced by <REDACTED>)
  * network checks: DNS resolve test, plain internet reachability, proxy settings state
- Step 1: rule-based analysis → deterministic cause + fixes.
- Step 2 (if API key set & enabled): send redacted DebugBundle to AI with a strict system prompt asking for JSON: { root_cause, evidence[], suggested_fix, code_change_hint, confidence }. Parse safely; on parse failure show raw text.
- Console shows: rule-based result + AI diagnosis cards + raw logs; ALL selectable/copyable.
- "Copy for IDE" button produces a Markdown block:
  ```
  ## Parvaz Debug Bundle
  - Version / OS / Mode / Stage / FailureCode
  ### Root cause (rule-based + AI)
  ### Evidence (log lines)
  ### Scan summary
  ### Sanitized config
  ### Task for IDE: "Fix the above issue. Identify the responsible file/service, propose a patch, add/adjust a test, and update FailureCode mapping if needed."
  ```
  so the developer can paste it straight into the IDE to patch the app.

SECURITY & PRIVACY
- Redact before any external call; show the user exactly what will be sent (preview dialog, can be turned off).
- No telemetry. AI call only on user's key.
- Verify sha256 of downloaded core binaries; ship hashes in repo.
- Always restore Windows proxy settings on exit, crash, and next launch (crash-recovery flag).

TESTING
- Unit tests: Redactor, scan scoring, failure-code mapping, config builder, state machine transitions.
- Fake services for integration tests of the connect flow (simulate each FailureCode).
- Provide `flutter test` and `flutter analyze` clean.

DELIVERY
Work in the order of the task list. After each task: summarize files changed, how to test manually, and any open risks.
```

---

# تسک‌بندی (Task Breakdown)

> هر تسک را جداگانه به IDE بده. بعد از هر تسک: اجرا، تست، commit.

## فاز 0 — راه‌اندازی (روز ۱)
- [ ] **T0.1** ساخت ریپو، ساختار پوشه‌ها، `LICENSE` (MIT)، `README` اولیه، `.gitignore`
  - *پذیرش:* پروژه روی ویندوز اجرا می‌شود و صفحه‌ی خالی نشان می‌دهد
- [ ] **T0.2** اجرای **Prompt 1** و تکمیل UI با داده‌ی نمایشی
  - *پذیرش:* ۵ صفحه قابل‌مرور، جریان فیک اتصال و شکست قابل مشاهده، `flutter analyze` تمیز

## فاز 1 — زیرساخت (روز ۱–۲)
- [ ] **T1.1** `LogService` + `Redactor` + تست‌ها
  - *پذیرش:* لاگ زنده در کنسول؛ توکن/کلید هیچ‌جا ساده نمایش داده نمی‌شود
- [ ] **T1.2** `FailureCode`ها و نگاشت پیام فارسی/توضیح/راه‌حل
- [ ] **T1.3** ذخیره‌سازی امن (Credential Manager) برای توکن کلودفلر و کلید AI

## فاز 2 — هسته و اتصال (روز ۲–۳)
- [ ] **T2.1** `CoreService`: دانلود/تأیید هش/اجرای sing-box، خواندن stdout/stderr به LogService
  - *پذیرش:* با یک کانفیگ دستی تست‌شده، اتصال برقرار می‌شود
- [ ] **T2.2** حالت System Proxy با بازگردانی امن (از جمله بعد از کرش)
- [ ] **T2.3** ماشین حالت اتصال (State Machine) و اتصال به UI

## فاز 3 — اسکنر IP زنده (روز ۳–۴) ⭐ ویژگی اصلی
- [ ] **T3.1** دریافت رنج‌های کلودفلر + fallback محلی
- [ ] **T3.2** Phase A: اسکن سریع TCP/TLS با concurrency قابل‌تنظیم
- [ ] **T3.3** Phase B: تست واقعی از مسیر Worker + محاسبه‌ی jitter و نرخ موفقیت
- [ ] **T3.4** Phase C: امتیازدهی، کش IPهای خوب، لیست failover
- [ ] **T3.5** استریم `ScanEvent` به پنل زنده (جدول، پیشرفت، IPs/sec، بهترین IP پین‌شده)، دکمه‌ی لغو
  - *پذیرش:* با زدن دکمه‌ی اتصال، کاربر لحظه‌به‌لحظه اسکن را می‌بیند و در نهایت بهترین IP انتخاب می‌شود

## فاز 4 — رله بدون VPS (روز ۴)
- [ ] **T4.1** قالب Worker در پوشه‌ی `/worker` + endpoint سلامت
- [ ] **T4.2** `CloudflareDeployService`: اعتبارسنجی توکن، دیپلوی، تولید UUID/مسیر تصادفی
- [ ] **T4.3** مدیریت چند رله، نمایش مصرف روزانه، تست سلامت

## فاز 5 — عیب‌یابی و AI (روز ۵) ⭐ ویژگی اصلی
- [ ] **T5.1** `DiagnosticsService`: DebugBundle + تحلیل قاعده‌محور
- [ ] **T5.2** `AiClient` (OpenAI-compatible) + صفحه‌ی تنظیمات AI + تست اتصال
- [ ] **T5.3** پیش‌نمایش داده‌ی ارسالی به AI + کارت «تشخیص AI» در کنسول
- [ ] **T5.4** دکمه‌های Copy all / Copy last error / **Copy for IDE** / Analyze with AI
  - *پذیرش:* با شبیه‌سازی هر `FailureCode`، علت و راه‌حل در کنسول، قابل‌کپی، نمایش داده می‌شود

## فاز 6 — مقاومت و پایداری (روز ۵–۶)
- [ ] **T6.1** `HealthService` + failover خودکار
- [ ] **T6.2** `ConfigUpdateService` با چند منبع پشتیبان و تأیید هش
- [ ] **T6.3** آیکون سینی، شروع با ویندوز، اتصال مجدد خودکار

## فاز 7 — انتشار (روز ۶)
- [ ] **T7.1** نصب‌کننده (Inno Setup) + نسخه‌ی Portable + انتشار هش فایل‌ها
- [ ] **T7.2** تست روی ویندوز تمیز (بدون Flutter و بدون ابزار توسعه)
- [ ] **T7.3** README (فارسی + انگلیسی) با GIF دمو، آموزش گرفتن API Token کلودفلر، بخش حریم خصوصی و ریسک‌ها
- [ ] **T7.4** ثبت پروژه در مسابقه (قبل از مهلت ۲۰ اکتبر، ۱۱:۵۹ شب IST) با یک روز بافر

---

## چرخه‌ی توسعه‌ی مداوم (بعد از هر شکست)
1. اتصال ناموفق ← کنسول علت را نشان می‌دهد
2. روی **Copy for IDE** بزن
3. متن را در IDE بچسبان ← IDE فایل/سرویس مسئول را پیدا و پچ می‌کند
4. تست جدید برای همان `FailureCode` اضافه شود تا دوباره تکرار نشود

## نکات مهم
- قبل از شروع، قوانین مسابقه را بخوان (یا در دیسکورد بپرس) که این نوع پروژه پذیرفته می‌شود.
- شرایط استفاده‌ی Cloudflare Workers برای کاربرد پروکسی را بررسی کن؛ معماری را طوری نگه دار که بتوان سرویس‌های دیگر (Deno Deploy و...) را جایگزین کرد.
- فایل اجرایی هسته ممکن است توسط آنتی‌ویروس هشدار بگیرد؛ هش‌ها را منتشر کن و در README توضیح بده.
- ریسک حقوقی و امنیتی شخصی‌ات را خودت ارزیابی کن و هویت انتشار ریپو را با آگاهی انتخاب کن.
