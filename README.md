# Simorgh

Simorgh is a Flutter desktop client for a privacy-first Cloudflare relay workflow. It is based on `Simorgh_PROMPTS.md` and the supplied Stitch screens. The UI still contains a safe mock/demo flow, while the service layer now provides opt-in real implementations behind injectable interfaces.

## Features

- Dark desktop shell with navigation rail.
- Home flow: Idle → Scanning → Connecting → Connected, plus a simulated failure state.
- Mock IP scan table, progress, telemetry and stage chips, plus a real TCP/TLS scanner service.
- Relay overview, selectable diagnostic console, AI settings and routing settings.
- Secure secrets, rotating JSONL logs, sing-box config/process lifecycle, Cloudflare Worker deployment, health checks, fallback config updates and auto-reconnect policy.
- Persian (default), English and Hindi localization. Persian uses RTL; Hindi and English use LTR.

The real services are not enabled by the demo UI by default. A verified sing-box binary,
relay configuration, user credentials and explicit Windows permissions are required before
using them. TUN/Wintun and a signed core distribution are not bundled in this repository.

## Requirements

- Flutter stable **3.47.5**, pinned in `.fvmrc`.
- Windows desktop tooling for the Windows release.

## Setup

```powershell
flutter pub get
```

## Run

```powershell
flutter run -d windows
```

Use the navigation rail to open Home, Relays, Console, AI Settings and Settings. The Home connect orb starts the safe demo flow. `Force Fail` previews diagnostics. Production services can be composed through `ConnectionOrchestrator` without putting credentials in widgets.

## Checks

On Windows PowerShell, run the commands directly:

```powershell
flutter analyze
flutter test
```

On Linux/macOS with GNU Make, the equivalent shortcuts are:

```bash
make analyze
make test
```

After `flutter pub get`, tests and analysis are offline-friendly. The Dockerfile pins the same Flutter version for reproducible CI.

## Build

```powershell
flutter build windows --release
```

The release output is under `build/windows/x64/runner/Release/`.

For a repeatable Windows build with checks and a SHA-256 manifest:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build_windows.ps1
```

The optional Inno Setup definition is `installer/Simorgh.iss`. Open it with
Inno Setup 6 after the release build to create a per-user installer under
`installer/Output/`. A portable distribution is the complete contents of
`build/windows/x64/runner/Release/`, including `SHA256SUMS.txt`.

## Security

Never put Cloudflare tokens, AI keys, UUIDs or private configuration in this repository. Store credentials through `flutter_secure_storage`/Windows Credential Manager, use the redacted `LogService`, verify a core SHA-256 before launch, and review all AI payloads before sending them. `.env.example` contains placeholders only.
