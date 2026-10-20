const defaultRelayWorkerScript = r'''
import { connect } from "cloudflare:sockets";

const EXPECTED_UUID = "__SIMORGH_UUID__";
const EXPECTED_PATH = "__SIMORGH_PATH__";

export default {
  async fetch(request) {
    const url = new URL(request.url);
    if (url.pathname === "/health") {
      return new Response("simorgh-relay-ok", { status: 200 });
    }
    if (url.pathname !== EXPECTED_PATH) {
      return new Response("Not found", { status: 404 });
    }
    if (request.headers.get("Upgrade") !== "websocket") {
      return new Response("WebSocket upgrade required", { status: 426 });
    }

    const [client, server] = Object.values(new WebSocketPair());
    server.accept();
    handleVlessSession(server).catch(() => server.close(1011, "relay failure"));
    return new Response(null, { status: 101, webSocket: client });
  }
};

async function handleVlessSession(webSocket) {
  let remote;
  let writer;
  let initialized = false;

  webSocket.addEventListener("message", async (event) => {
    const bytes = await asBytes(event.data);
    if (!initialized) {
      const request = parseVlessRequest(bytes);
      if (!request || request.uuid !== normalizeUuid(EXPECTED_UUID) || request.command !== 1) {
        webSocket.close(1008, "invalid request");
        return;
      }
      remote = connect({ hostname: request.host, port: request.port });
      writer = remote.writable.getWriter();
      initialized = true;
      webSocket.send(new Uint8Array([0, 0]));
      if (request.payload.byteLength > 0) await writer.write(request.payload);
      pumpRemote(remote, webSocket);
      return;
    }
    if (writer) await writer.write(bytes);
  });

  webSocket.addEventListener("close", async () => {
    try { if (writer) await writer.close(); } catch (_) {}
    try { if (remote) remote.close(); } catch (_) {}
  });
}

async function pumpRemote(remote, webSocket) {
  const reader = remote.readable.getReader();
  try {
    while (true) {
      const next = await reader.read();
      if (next.done) break;
      webSocket.send(next.value);
    }
  } finally {
    try { reader.releaseLock(); } catch (_) {}
    try { webSocket.close(1000, "upstream closed"); } catch (_) {}
  }
}

function parseVlessRequest(bytes) {
  if (bytes.byteLength < 24 || bytes[0] !== 1) return null;
  const uuid = toHex(bytes.slice(1, 17));
  const addonLength = bytes[17];
  let offset = 18 + addonLength;
  if (offset + 4 > bytes.byteLength) return null;
  const command = bytes[offset++];
  const port = (bytes[offset] << 8) | bytes[offset + 1];
  offset += 2;
  const addressType = bytes[offset++];
  let host;
  if (addressType === 1) {
    if (offset + 4 > bytes.byteLength) return null;
    host = Array.from(bytes.slice(offset, offset + 4)).join(".");
    offset += 4;
  } else if (addressType === 2) {
    const length = bytes[offset++];
    if (offset + length > bytes.byteLength) return null;
    host = new TextDecoder().decode(bytes.slice(offset, offset + length));
    offset += length;
  } else if (addressType === 3) {
    if (offset + 16 > bytes.byteLength) return null;
    const parts = [];
    for (let i = 0; i < 16; i += 2) parts.push(((bytes[offset + i] << 8) | bytes[offset + i + 1]).toString(16));
    host = parts.join(":");
    offset += 16;
  } else {
    return null;
  }
  return { uuid, command, port, host, payload: bytes.slice(offset) };
}

function normalizeUuid(value) { return value.replaceAll("-", "").toLowerCase(); }
function toHex(bytes) { return Array.from(bytes).map((value) => value.toString(16).padStart(2, "0")).join(""); }
async function asBytes(value) {
  if (value instanceof ArrayBuffer) return new Uint8Array(value);
  if (ArrayBuffer.isView(value)) return new Uint8Array(value.buffer, value.byteOffset, value.byteLength);
  return new TextEncoder().encode(String(value));
}
''';
