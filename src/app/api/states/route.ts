import { getEngine } from "@/lib/engine";
import { json } from "@/lib/http";

export const dynamic = "force-dynamic";

/** State-by-state status. */
export async function GET(req: Request) {
  const p = new URL(req.url).searchParams;
  return json({ states: getEngine().stateLevels({ slug: p.get("service") || undefined, category: p.get("category") || undefined }) });
}
