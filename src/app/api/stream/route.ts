import { getEngine } from "@/lib/engine";
import type { AlertMessage } from "@/lib/alerts";

export const dynamic = "force-dynamic";

/**
 * Server-sent events: "tick" after each recompute (clients refetch what
 * they show), "change" when a national/state status changes, and "alert"
 * for the subscriptions named in ?subs=id1,id2.
 */
export async function GET(req: Request) {
  const engine = getEngine();
  const subs = new Set((new URL(req.url).searchParams.get("subs") ?? "").split(",").filter(Boolean).slice(0, 20));
  const encoder = new TextEncoder();
  let cleanup = () => {};

  const stream = new ReadableStream<Uint8Array>({
    start(controller) {
      const send = (event: string, data: unknown) => {
        try {
          controller.enqueue(encoder.encode(`event: ${event}\ndata: ${JSON.stringify(data)}\n\n`));
        } catch {
          cleanup();
        }
      };
      const onTick = (t: number) => send("tick", { t });
      const onChange = (c: unknown) => send("change", c);
      const onAlert = (m: AlertMessage) => subs.has(m.subscriptionId) && send("alert", m);
      const ping = setInterval(() => send("ping", {}), 25_000);
      engine.bus.on("tick", onTick);
      engine.bus.on("change", onChange);
      engine.bus.on("alert", onAlert);
      cleanup = () => {
        clearInterval(ping);
        engine.bus.off("tick", onTick);
        engine.bus.off("change", onChange);
        engine.bus.off("alert", onAlert);
      };
      req.signal.addEventListener("abort", () => {
        cleanup();
        try {
          controller.close();
        } catch {}
      });
      send("hello", { t: Date.now() });
    },
    cancel() {
      cleanup();
    },
  });

  return new Response(stream, {
    headers: { "Content-Type": "text/event-stream", "Cache-Control": "no-cache, no-transform", Connection: "keep-alive" },
  });
}
