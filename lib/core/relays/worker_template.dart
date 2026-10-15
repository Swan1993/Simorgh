const defaultRelayWorkerScript = r'''
export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (url.pathname === env.HEALTH_PATH) {
      return new Response("simorgh-relay-ok", { status: 200 });
    }
    return new Response("Simorgh relay is ready", { status: 200 });
  }
};
''';
