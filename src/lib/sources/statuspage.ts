// Official provider status pages in the Atlassian Statuspage format
// (`/api/v2/summary.json`), which many platforms publish openly.

import { SERVICES } from "../services";
import type { SourceSignal, StatusLevel } from "../types";
import type { Env, SourceAdapter, SourceInfo } from "./types";

export const STATUSPAGE_SOURCE: SourceInfo = {
  id: "official",
  name: "Official status pages",
  url: "https://www.atlassian.com/software/statuspage",
  attribution: "Official provider status pages",
  categories: [],
  serviceSlugs: SERVICES.filter((s) => s.statuspageApi).map((s) => s.slug),
  kind: "official",
};

interface Summary {
  status?: { indicator?: string; description?: string };
  incidents?: { name?: string; status?: string; impact?: string; incident_updates?: { body?: string }[] }[];
}

const INDICATOR: Record<string, StatusLevel> = { none: "ok", minor: "possible", major: "problems", critical: "problems" };

export function mapSummary(slug: string, body: Summary, now: number): SourceSignal {
  const level = INDICATOR[body.status?.indicator ?? "none"] ?? "ok";
  const incident = body.incidents?.find((i) => i.status !== "resolved");
  return {
    sourceId: STATUSPAGE_SOURCE.id,
    serviceSlug: slug,
    observedAt: now,
    level,
    official: level !== "ok",
    message: (incident?.incident_updates?.[0]?.body ?? incident?.name ?? body.status?.description)?.slice(0, 280),
    scope: {},
  };
}

export function statuspageAdapter(env: Env = process.env): SourceAdapter {
  const enabled = env.SOURCE_STATUSPAGES_ENABLED === "true";
  return {
    info: STATUSPAGE_SOURCE,
    enabled,
    disabledReason: enabled ? undefined : "Off by default. Set SOURCE_STATUSPAGES_ENABLED=true.",
    async poll(now) {
      const targets = SERVICES.filter((s) => s.statuspageApi);
      const results = await Promise.allSettled(
        targets.map(async (s) => {
          const res = await fetch(s.statuspageApi!, { signal: AbortSignal.timeout(8_000) });
          if (!res.ok) throw new Error(`${s.name} status page returned ${res.status}`);
          return mapSummary(s.slug, (await res.json()) as Summary, now);
        }),
      );
      return results.flatMap((r) => (r.status === "fulfilled" ? [r.value] : []));
    },
  };
}
