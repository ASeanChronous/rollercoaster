import { getEngine } from "@/lib/engine";
import { lookupZip } from "@/lib/geo";
import { error, json, scopeFrom } from "@/lib/http";

export const dynamic = "force-dynamic";

/** Active severe-weather warnings that could cause outages, for a state or near a ZIP. */
export async function GET(req: Request) {
  const scope = scopeFrom(new URL(req.url).searchParams);
  if (typeof scope === "string") return error(scope);
  const weather = getEngine().weather;
  if (scope.zip) {
    const place = lookupZip(scope.zip)!;
    return json({ alerts: await weather.forPoint(place.lat, place.lng) });
  }
  if (scope.state) return json({ alerts: await weather.forState(scope.state) });
  return error("Pass zip or state.");
}
