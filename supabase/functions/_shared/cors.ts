// Studio runs in the browser (audiokiddo.pl/studio, or localhost while developing), so the
// functions it calls must answer the CORS preflight and name the allowed origin.

const ALLOWED = [/^https:\/\/(www\.)?audiokiddo\.pl$/, /^http:\/\/localhost(:\d+)?$/, /^http:\/\/127\.0\.0\.1(:\d+)?$/];

export function allowedOrigin(origin: string | null): string | null {
  return origin && ALLOWED.some((r) => r.test(origin)) ? origin : null;
}

/** Wraps a handler: answers OPTIONS and adds the CORS headers for allowed origins. */
export function withCors(handler: (req: Request) => Promise<Response>): (req: Request) => Promise<Response> {
  return async (req) => {
    const origin = allowedOrigin(req.headers.get("Origin"));
    const headers: Record<string, string> = origin
      ? {
        "Access-Control-Allow-Origin": origin,
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Vary": "Origin",
      }
      : {};
    if (req.method === "OPTIONS") return new Response(null, { status: origin ? 204 : 403, headers });
    const response = await handler(req);
    for (const [k, v] of Object.entries(headers)) response.headers.set(k, v);
    return response;
  };
}
