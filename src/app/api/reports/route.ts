import { getEngine } from "@/lib/engine";
import { clientIp, error, json } from "@/lib/http";
import type { ProblemType } from "@/lib/types";

export const dynamic = "force-dynamic";

/** Submit a crowd report (PRD §6.7). */
export async function POST(req: Request) {
  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return error("Invalid JSON.");
  }
  const str = (k: string) => (typeof body[k] === "string" ? (body[k] as string) : "");
  const result = getEngine().report(
    {
      serviceSlug: str("service"),
      zip: str("zip").trim(),
      problemType: str("problemType") as ProblemType,
      comment: str("comment") || undefined,
      deviceId: str("deviceId").slice(0, 64),
      ip: clientIp(req),
    },
    Date.now(),
  );
  if (!result.ok) {
    return error(result.error, result.status, result.retryAfterSec ? { "Retry-After": String(result.retryAfterSec) } : undefined);
  }
  return json({ ok: true, id: result.report.id, nearbyLastHour: result.nearby }, { status: 201 });
}
