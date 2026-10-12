import { getEngine } from "@/lib/engine";
import { error, json, scopeFrom } from "@/lib/http";
import { CATEGORY_LABEL, type Category } from "@/lib/types";

export const dynamic = "force-dynamic";

/** Live overview: every service with its status at the requested scope. */
export async function GET(req: Request) {
  const params = new URL(req.url).searchParams;
  const scope = scopeFrom(params);
  if (typeof scope === "string") return error(scope);
  const category = params.get("category") as Category | null;
  if (category && !(category in CATEGORY_LABEL)) return error("Unknown category.");
  const services = getEngine().summaries(scope).filter((s) => !category || s.category === category);
  return json({ scope, services, updatedAt: Date.now() });
}
