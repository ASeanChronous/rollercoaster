import { getEngine } from "@/lib/engine";
import { error, json, scopeFrom } from "@/lib/http";
import { getService } from "@/lib/services";
import { HOUR } from "@/lib/time";

export const dynamic = "force-dynamic";

/** Everything a service page needs: status, curve, breakdown, history, sources. */
export async function GET(req: Request, ctx: { params: Promise<{ slug: string }> }) {
  const { slug } = await ctx.params;
  const service = getService(slug);
  if (!service) return error("Unknown service.", 404);
  const scope = scopeFrom(new URL(req.url).searchParams);
  if (typeof scope === "string") return error(scope);

  const engine = getEngine();
  const now = Date.now();
  return json({
    service,
    scope,
    status: engine.status(slug, scope, now),
    national: scope.state || scope.zip ? engine.status(slug, {}, now) : undefined,
    curve: engine.curve(slug, scope, now),
    breakdown: engine.breakdown(slug, scope, now),
    history: engine.history({ slug }, now - 48 * HOUR).slice(0, 20),
    uptime24h: engine.uptime(slug, now, 24),
    sources: engine.sourcesFor(service).map((s) => ({ id: s.id, name: s.name, url: s.url, attribution: s.attribution })),
    updatedAt: now,
  });
}
