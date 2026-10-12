import { getState, lookupZip, zipFromCoords } from "@/lib/geo";
import { error, json } from "@/lib/http";

export const dynamic = "force-dynamic";

/** Resolve a ZIP or GPS coordinate to a ZIP/city/state. Coordinates are not stored. */
export async function GET(req: Request) {
  const p = new URL(req.url).searchParams;
  const zip = p.get("zip");
  const place = zip ? lookupZip(zip.trim()) : zipFromCoords(Number(p.get("lat")), Number(p.get("lng")));
  if (!place) return error(zip ? "We couldn't find that ZIP code." : "We couldn't match your location to a US ZIP code.", 404);
  return json({ zip: place.zip, city: place.city, state: place.state, stateName: getState(place.state)?.name, lat: place.lat, lng: place.lng });
}
