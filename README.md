# Simorgh

Simorgh is a Windows-focused Flutter desktop client for a privacy-first Cloudflare relay workflow. The production composition root connects Home to secure storage, relay persistence, the real scanner, sing-box lifecycle, health checks and Windows proxy cleanup. A no-services `SimorghApp()` remains available for widget previews.

## Features

- Dark desktop shell with navigation rail.
- Home flow: Idle → Scanning → Connecting → Connected, plus a simulated failure state.
- Live IP scan events, progress, telemetry and stage chips when an active relay and verified core are configured, plus a real TCP/TLS scanner service.
- Relay overview, selectable diagnostic console, AI settings and routing settings.
- Secure secrets, rotating JSONL logs, sing-box config/process lifecycle, Cloudflare Worker deployment, health checks, fallback config updates and auto-reconnect policy.
- Persian (default), English and Hindi localization. Persian uses RTL; Hindi and English use LTR.

A verified `sing-box.exe`, relay configuration, user credentials and explicit Windows
permissions are required before using the real path. TUN/Wintun and a signed core
distribution are not bundled in this repository. The current real mode uses the Windows
system proxy and restores it on disconnect, failure and tray exit.

## Requirements

- Flutter stable **3.47.5**, pinned in `.fvmrc`.
- Windows desktop tooling for the Windows release: Visual Studio Desktop development
  with C++, MSVC x64/x86 build tools, a Windows SDK and CMake tools. The secure
  storage plugin uses Windows DPAPI and does not require the optional ATL headers.

## Setup

```powershell
flutter pub get
```

## Run

```powershell
flutter run -d windows
```

Use Relays → Add relay to store a relay hostname, port, UUID and WebSocket path securely.
Mark one relay active, place the verified core binary and its 64-character hash manifest
in the application-support core directory, then press Connect. Home subscribes to real
session events; Cancel/Disconnect stops scanning, sing-box and the system proxy.

For automatic relay creation, open **Relays → Auto-deploy** and enter a Cloudflare API
token, account ID, relay name and Worker script name. The app verifies the token,
uploads the bundled VLESS-over-WebSocket Worker, generates the UUID and path, saves the
relay, and marks the first relay active. The token and account ID are stored through
the platform secure store; they are never written to relay metadata or logs. The token
needs permission to edit Workers Scripts for the selected account, and the account must
have a `workers.dev` subdomain available.

The app now installs the bundled signed-by-hash Windows core on first launch.
The resolver expects these files below the Windows application-support directory:

```text
data/core/sing-box.exe
data/core/sing-box.sha256
```

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

Secure values use the `get_x_storage_secure` plugin from the public Git repository.
On Windows it stores user-scoped DPAPI blobs and does not require the ATL headers
used by the removed ATL-dependent plugin. The Git dependency is
locked to its resolved commit in `pubspec.lock`.

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

Never put Cloudflare tokens, AI keys, UUIDs or private configuration in this repository. Store credentials through `get_x_storage_secure`/Windows DPAPI, use the redacted `LogService`, verify a core SHA-256 before launch, and review all AI payloads before sending them. `.env.example` contains placeholders only.
