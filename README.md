# Simorgh

Simorgh is a Flutter desktop UI prototype for a privacy-first Cloudflare tunnel client. It is based on `Simorgh_PROMPTS.md` and the supplied Stitch screens. The current milestone is deliberately UI-only: the scanner, relays, diagnostics and AI actions use mock data and do not make network calls.

## Scope

- Dark desktop shell with a navigation rail.
- Home flow: Idle → Scanning → Connecting → Connected, plus a simulated failure state.
- Live mock IP scan table, progress, telemetry and stage chips.
- Relay overview, selectable diagnostic console, AI settings and routing settings.
- Persian (default), English and Hindi localization with RTL support for Persian and Hindi.
- No real API key, Cloudflare token, proxy change, TUN adapter or sidecar process is included.

## Requirements

- Flutter stable **3.35.5** (pinned in `.fvmrc`).
- Dart SDK supplied by that Flutter release.
- Windows desktop tooling for the target release. Linux can run tests and analyze Dart code, but cannot produce a Windows executable without Windows tooling.

## Setup and run

```bash
flutter pub get
flutter run -d windows
```

Use the navigation rail to open Home, Relays, Console, AI Settings and Settings. The Home connect orb starts the fake scan flow. The `Force Fail` button previews diagnostics.

## Checks

The project test command is:

```bash
make test
```

Static analysis:

```bash
make analyze
```

After dependencies are cached, both commands run without network access. The container recipe uses the same test command:

```bash
docker build -t simorgh-test .
docker run --rm simorgh-test
```

## Build / deploy

On Windows with Flutter desktop enabled:

```powershell
flutter build windows --release
```

Release output is under `build/windows/x64/runner/Release/`. Real networking, Worker deployment, TUN and secure secret storage are deferred to the next phase in `Simorgh_PROMPTS.md`.

## Security

Never put Cloudflare tokens, AI keys, UUIDs or private configuration in this repository. The current UI uses placeholders only. Future services must use Windows Credential Manager and redact logs before diagnostic export or AI requests.
