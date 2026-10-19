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
token, account ID, relay name and Worker script name. The app verifies the token, reads
the account's `workers.dev` subdomain, uploads the bundled VLESS-over-WebSocket Worker,
generates the UUID and path, saves the relay with the full Worker hostname, and marks
the first relay active. The token and account ID are stored through the platform secure
store; they are never written to relay metadata or logs. The token needs permission to
edit Workers Scripts for the selected account, and the account must have a `workers.dev`
subdomain available. The Worker name must contain only letters, numbers and dashes and
must not start or end with a dash.

The app now installs the bundled signed-by-hash Windows core on first launch.
The resolver expects these files below the Windows application-support directory:

```text
data/core/sing-box.exe
data/core/sing-box.sha256
```

## ساخت Worker در Cloudflare؛ راهنمای کامل برای کاربر

### روش پیشنهادی: ساخت خودکار از داخل Simorgh

اگر فقط می‌خواهید برنامه را راه‌اندازی کنید، نیازی به کپی‌کردن کد Worker ندارید:

1. در Cloudflare یک API Token با دسترسی **Workers Scripts: Edit** برای Account موردنظر
   بسازید.
2. مطمئن شوید برای Account شما یک `workers.dev` subdomain فعال است.
3. در Simorgh به **Relays → Auto-deploy** بروید.
4. نام Relay، نام Worker، Account ID و API Token را وارد کنید.
5. روی **Deploy** بزنید.

Simorgh توکن را بررسی می‌کند، subdomain واقعی Account را می‌خواند، کد Worker را
آپلود می‌کند، UUID و مسیر WebSocket تصادفی می‌سازد، Relay را ذخیره می‌کند و اگر اولین
Relay باشد آن را فعال می‌کند. در این روش کد زیر را دستی در Cloudflare paste نکنید.

### روش دستی: کپی‌کردن کد Worker

از این روش وقتی استفاده کنید که می‌خواهید Worker را خودتان در Cloudflare بسازید یا
کد آن را بررسی کنید. این راهنما برای Cloudflare Dashboard نوشته شده است و ممکن است
نام بعضی دکمه‌ها در نسخه‌های مختلف کمی فرق کند.

#### مرحله ۱: ورود به Cloudflare

1. وارد [Cloudflare Dashboard](https://dash.cloudflare.com/) شوید.
2. Account موردنظر را انتخاب کنید.
3. از منوی **Workers & Pages** وارد بخش Workers شوید.
4. اگر هنوز subdomain ندارید، از بخش **Workers & Pages** گزینه **Change** کنار
   **Your subdomain** را انتخاب کنید و یک subdomain برای Account بسازید.

#### مرحله ۲: ساخت Worker

1. روی **Create application** یا **Create Worker** بزنید.
2. نام Worker را وارد کنید؛ برای نمونه:

   ```text
   simorgh-relay
   ```

   نام باید فقط شامل حروف انگلیسی، عدد و `-` باشد، حداکثر ۶۳ کاراکتر داشته باشد و
   با `-` شروع یا تمام نشود.
3. روی **Deploy** بزنید تا Worker اولیه ساخته شود.
4. Worker ساخته‌شده را باز کنید و وارد **Edit code** شوید.

#### مرحله ۳: ساخت مقادیر محرمانه

Worker برای قبول‌کردن اتصال به دو مقدار نیاز دارد: یک UUID و یک مسیر WebSocket.
این دو مقدار را خودتان بسازید و در اختیار دیگران قرار ندهید.

در PowerShell می‌توانید یک UUID بسازید:

```powershell
[guid]::NewGuid().Guid
```

برای شروع، یک مسیر مانند نمونه زیر انتخاب کنید:

```text
/simorgh-demo-7f3a
```

مسیر باید با `/` شروع شود و در کد Worker و تنظیمات Relay در Simorgh دقیقاً یکسان
باشد. نمونه‌های زیر فقط نمونه هستند؛ برای استفاده واقعی UUID و path مخصوص خودتان
را بسازید.

#### مرحله ۴: کد کامل Worker

تمام کد موجود در ویرایشگر Cloudflare را پاک کنید و کد زیر را کامل paste کنید. سپس
مقدارهای `EXPECTED_UUID` و `EXPECTED_PATH` را با مقادیر خودتان عوض کنید:

```javascript
import { connect } from "cloudflare:sockets";

// این دو مقدار باید با Relay داخل Simorgh دقیقاً یکی باشند.
const EXPECTED_UUID = "8f4d6f2a-4b2c-4e6a-9d31-7c1b6a8e2190";
const EXPECTED_PATH = "/simorgh-demo-7f3a";

export default {
  async fetch(request) {
    const url = new URL(request.url);

    // برای بررسی سالم‌بودن Worker.
    if (url.pathname === "/health") {
      return new Response("simorgh-relay-ok", { status: 200 });
    }

    // فقط مسیر محرمانه Relay مجاز است.
    if (url.pathname !== EXPECTED_PATH) {
      return new Response("Not found", { status: 404 });
    }

    // اتصال Relay باید WebSocket باشد.
    if (request.headers.get("Upgrade") !== "websocket") {
      return new Response("WebSocket upgrade required", { status: 426 });
    }

    const [client, server] = Object.values(new WebSocketPair());
    server.accept();

    handleVlessSession(server).catch(() => {
      try {
        server.close(1011, "relay failure");
      } catch (_) {}
    });

    return new Response(null, {
      status: 101,
      webSocket: client,
    });
  },
};

async function handleVlessSession(webSocket) {
  let remote;
  let writer;
  let initialized = false;

  webSocket.addEventListener("message", async (event) => {
    const bytes = await asBytes(event.data);

    if (!initialized) {
      const request = parseVlessRequest(bytes);

      if (
        !request ||
        request.uuid !== normalizeUuid(EXPECTED_UUID) ||
        request.command !== 1
      ) {
        webSocket.close(1008, "invalid request");
        return;
      }

      remote = connect({
        hostname: request.host,
        port: request.port,
      });

      writer = remote.writable.getWriter();
      initialized = true;

      // پاسخ اولیه VLESS.
      webSocket.send(new Uint8Array([0, 0]));

      if (request.payload.byteLength > 0) {
        await writer.write(request.payload);
      }

      pumpRemote(remote, webSocket);
      return;
    }

    if (writer) {
      await writer.write(bytes);
    }
  });

  webSocket.addEventListener("close", async () => {
    try {
      if (writer) await writer.close();
    } catch (_) {}

    try {
      if (remote) remote.close();
    } catch (_) {}
  });
}

async function pumpRemote(remote, webSocket) {
  const reader = remote.readable.getReader();

  try {
    while (true) {
      const next = await reader.read();

      if (next.done) {
        break;
      }

      webSocket.send(next.value);
    }
  } finally {
    try {
      reader.releaseLock();
    } catch (_) {}

    try {
      webSocket.close(1000, "upstream closed");
    } catch (_) {}
  }
}

function parseVlessRequest(bytes) {
  // حداقل اندازه header موردنیاز VLESS.
  if (bytes.byteLength < 24 || bytes[0] !== 1) {
    return null;
  }

  const uuid = toHex(bytes.slice(1, 17));
  const addonLength = bytes[17];
  let offset = 18 + addonLength;

  if (offset + 4 > bytes.byteLength) {
    return null;
  }

  const command = bytes[offset++];
  const port = (bytes[offset] << 8) | bytes[offset + 1];
  offset += 2;
  const addressType = bytes[offset++];
  let host;

  // IPv4.
  if (addressType === 1) {
    if (offset + 4 > bytes.byteLength) {
      return null;
    }

    host = Array.from(bytes.slice(offset, offset + 4)).join(".");
    offset += 4;
  }

  // نام دامنه.
  else if (addressType === 2) {
    const length = bytes[offset++];

    if (offset + length > bytes.byteLength) {
      return null;
    }

    host = new TextDecoder().decode(bytes.slice(offset, offset + length));
    offset += length;
  }

  // IPv6.
  else if (addressType === 3) {
    if (offset + 16 > bytes.byteLength) {
      return null;
    }

    const parts = [];

    for (let i = 0; i < 16; i += 2) {
      parts.push(
        ((bytes[offset + i] << 8) | bytes[offset + i + 1]).toString(16),
      );
    }

    host = parts.join(":");
    offset += 16;
  } else {
    return null;
  }

  return {
    uuid,
    command,
    port,
    host,
    payload: bytes.slice(offset),
  };
}

function normalizeUuid(value) {
  return value.replaceAll("-", "").toLowerCase();
}

function toHex(bytes) {
  return Array.from(bytes)
    .map((value) => value.toString(16).padStart(2, "0"))
    .join("");
}

async function asBytes(value) {
  if (value instanceof ArrayBuffer) {
    return new Uint8Array(value);
  }

  if (ArrayBuffer.isView(value)) {
    return new Uint8Array(value.buffer, value.byteOffset, value.byteLength);
  }

  return new TextEncoder().encode(String(value));
}
```

#### مرحله ۵: انتشار Worker

1. در ویرایشگر Cloudflare مطمئن شوید دو مقدار زیر عوض شده‌اند:

   ```javascript
   const EXPECTED_UUID = "UUID-خودتان";
   const EXPECTED_PATH = "/مسیر-خودتان";
   ```

2. روی **Save and deploy** یا **Deploy** بزنید.
3. چند لحظه صبر کنید تا وضعیت Worker به **Deployed** تغییر کند.
4. در بخش تنظیمات Worker، فعال‌بودن مسیر `workers.dev` را بررسی کنید.

آدرس عمومی Worker معمولاً به این شکل است:

```text
<worker-name>.<account-subdomain>.workers.dev
```

برای نمونه:

```text
simorgh-relay.myaccount.workers.dev
```

#### مرحله ۶: تست Worker

در مرورگر یا PowerShell آدرس سلامت را باز کنید:

```powershell
Invoke-WebRequest `
  -Uri "https://<worker-name>.<account-subdomain>.workers.dev/health" `
  -UseBasicParsing
```

پاسخ صحیح باید این باشد:

```text
simorgh-relay-ok
```

اگر پاسخ `404` گرفتید، مسیر `/health` را دقیقاً بررسی کنید. اگر خطای DNS گرفتید،
`workers.dev` subdomain یا نام Worker هنوز آماده نشده است. اگر کد Deploy نمی‌شود،
نام Worker و دسترسی Account را بررسی کنید.

#### مرحله ۷: واردکردن Relay در Simorgh

در برنامه به **Relays → Add relay** بروید و مقادیر زیر را وارد کنید:

| فیلد Simorgh | مقدار |
| --- | --- |
| Name | یک نام دلخواه، مانند `Cloudflare Relay` |
| Hostname | بدون `https://`؛ مانند `simorgh-relay.myaccount.workers.dev` |
| Port | `443` |
| UUID | همان مقدار `EXPECTED_UUID` در Worker |
| WebSocket path | همان مقدار `EXPECTED_PATH` در Worker، مانند `/simorgh-demo-7f3a` |

Relay را ذخیره کنید، آن را **Active** کنید و سپس اتصال را از صفحه Home شروع کنید.

UUID، path، API Token و Account ID اطلاعات محرمانه هستند. آن‌ها را در Git، issue،
لاگ یا پیام عمومی قرار ندهید. اگر از **Auto-deploy** استفاده می‌کنید، روش دستی و
کد بالا لازم نیست؛ Simorgh مقادیر امن و تصادفی تولید و آن‌ها را در secure storage
ذخیره می‌کند.

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
