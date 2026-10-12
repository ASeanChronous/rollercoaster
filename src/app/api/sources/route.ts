import { getEngine } from "@/lib/engine";
import { json } from "@/lib/http";

export const dynamic = "force-dynamic";

/** Which data sources are live, and why the others are off. */
export async function GET() {
  const engine = getEngine();
  return json({
    demo: engine.demo,
    sources: engine.adapters.map((a) => ({
      ...a.info,
      enabled: a.enabled,
      simulated: engine.demo && !a.enabled && a.info.kind === "aggregator",
      disabledReason: a.disabledReason,
    })),
    errors: engine.lastPollErrors,
  });
}
