import { getEngine } from "@/lib/engine";
import { json } from "@/lib/http";

export const dynamic = "force-dynamic";

/** Health check for the host. Fails if the engine has stopped ticking. */
export async function GET() {
  const engine = getEngine();
  const ageSec = Math.round((Date.now() - engine.lastTickAt) / 1000);
  const healthy = ageSec < 5 * 60;
  return json({ ok: healthy, demo: engine.demo, lastTickSecondsAgo: ageSec }, { status: healthy ? 200 : 503 });
}
