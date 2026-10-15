# Simorgh

Simorgh is a Flutter desktop UI prototype for a privacy-first Cloudflare tunnel client. It is based on `Simorgh_PROMPTS.md` and the supplied Stitch screens. The current milestone is UI-only: scanner, relays, diagnostics and AI actions use mock data and make no network calls.

## Features

- Dark desktop shell with navigation rail.
- Home flow: Idle → Scanning → Connecting → Connected, plus a simulated failure state.
- Mock IP scan table, progress, telemetry and stage chips.
- Relay overview, selectable diagnostic console, AI settings and routing settings.
- Persian (default), English and Hindi localization. Persian uses RTL; Hindi and English use LTR.

Real sing-box/Xray, Cloudflare Worker deployment, TUN, proxy changes and AI API calls are not implemented yet.

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

Use the navigation rail to open Home, Relays, Console, AI Settings and Settings. The Home connect orb starts the fake scan flow. `Force Fail` previews diagnostics.

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

## Security

Never put Cloudflare tokens, AI keys, UUIDs or private configuration in this repository. The current UI uses placeholders only. Future services must use Windows Credential Manager and redact logs before diagnostic export or AI requests.
