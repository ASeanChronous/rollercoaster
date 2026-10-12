import { getEngine } from "@/lib/engine";
import { error, json } from "@/lib/http";
import { getService } from "@/lib/services";

export const dynamic = "force-dynamic";

const WINDOWS = new Set([60, 360, 1440]);

/** Aggregated report cells for the outage map. Only cells with 5+ reports are returned. */
export async function GET(req: Request) {
  const p = new URL(req.url).searchParams;
  const slug = p.get("service") || undefined;
  if (slug && !getService(slug)) return error("Unknown service.");
  const minutes = Number(p.get("minutes") ?? 60);
  if (!WINDOWS.has(minutes)) return error("minutes must be 60, 360 or 1440.");
  const engine = getEngine();
  const category = p.get("category") || undefined;
  return json({
    cells: engine.mapCells({ slug, category, minutes }, Date.now()),
    states: engine.stateLevels({ slug, category }),
  });
}
