import { getEngine } from "@/lib/engine";
import { lookupZip } from "@/lib/geo";
import { error, json } from "@/lib/http";
import { getService } from "@/lib/services";

export const dynamic = "force-dynamic";

const EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const MAX_SERVICES = 25;

/** Create an alert subscription for a ZIP and a list of services. */
export async function POST(req: Request) {
  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return error("Invalid JSON.");
  }
  const zip = typeof body.zip === "string" ? body.zip.trim() : "";
  if (!lookupZip(zip)) return error("Enter a valid US ZIP code.");
  const services = Array.isArray(body.services) ? body.services.filter((s): s is string => typeof s === "string" && Boolean(getService(s))) : [];
  if (!services.length) return error("Choose at least one service.");
  if (services.length > MAX_SERVICES) return error(`Choose up to ${MAX_SERVICES} services.`);
  const email = typeof body.email === "string" && body.email.trim() ? body.email.trim() : undefined;
  if (email && !EMAIL.test(email)) return error("Enter a valid email address.");
  const browser = body.browser !== false;
  if (!email && !browser) return error("Choose at least one way to be notified.");
  const minLevel = body.minLevel === "problems" ? "problems" : "possible";

  const sub = getEngine().alerts.subscribe({ zip, serviceSlugs: [...new Set(services)], email, browser, minLevel }, Date.now());
  return json({ id: sub.id, token: sub.token, zip: sub.zip, services: sub.serviceSlugs, minLevel: sub.minLevel, email: sub.email, browser: sub.browser }, { status: 201 });
}

/** Read a subscription and its recent alerts. Requires the token returned at creation. */
export async function GET(req: Request) {
  const p = new URL(req.url).searchParams;
  const engine = getEngine();
  const sub = engine.alerts.get(p.get("id") ?? "", p.get("token") ?? "");
  if (!sub) return error("Subscription not found.", 404);
  return json({
    id: sub.id, zip: sub.zip, services: sub.serviceSlugs, minLevel: sub.minLevel, email: sub.email, browser: sub.browser,
    messages: engine.alerts.messagesFor(sub.id).slice(-50).reverse(),
  });
}

export async function DELETE(req: Request) {
  const p = new URL(req.url).searchParams;
  const ok = getEngine().alerts.unsubscribe(p.get("id") ?? "", p.get("token") ?? "");
  return ok ? json({ ok: true }) : error("Subscription not found.", 404);
}
