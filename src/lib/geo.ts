// Geography helpers: ZIP lookup, state metadata, and privacy-preserving grid cells.

import zipcodes from "zipcodes";
import type { Service } from "./types";
import { STATES, type StateInfo } from "./geo-states";

export { STATES, type StateInfo } from "./geo-states";

const STATE_BY_CODE = new Map(STATES.map((s) => [s.code, s]));
const TOTAL_POP = STATES.reduce((sum, s) => sum + s.pop, 0);

export function getState(code: string): StateInfo | undefined {
  return STATE_BY_CODE.get(code.toUpperCase());
}

export interface Place {
  zip: string;
  city: string;
  state: string;
  lat: number;
  lng: number;
}

export function lookupZip(zip: string): Place | undefined {
  if (!/^\d{5}$/.test(zip)) return undefined;
  const z = zipcodes.lookup(zip);
  if (!z || z.country !== "US" || !STATE_BY_CODE.has(z.state)) return undefined;
  return { zip: z.zip, city: z.city, state: z.state, lat: z.latitude, lng: z.longitude };
}

/** Nearest ZIP to a coordinate. Used for GPS: we keep the ZIP, not the coordinate. */
export function zipFromCoords(lat: number, lng: number): Place | undefined {
  if (!Number.isFinite(lat) || !Number.isFinite(lng)) return undefined;
  const z = zipcodes.lookupByCoords(lat, lng);
  return z ? lookupZip(z.zip) : undefined;
}

let zipsByState: Map<string, Place[]> | undefined;

/** All ZIPs in a state, for distributing simulated signals. Built lazily. */
export function zipsInState(state: string): Place[] {
  if (!zipsByState) {
    zipsByState = new Map();
    for (const code of Object.keys(zipcodes.codes)) {
      const p = lookupZip(code);
      if (!p) continue;
      const list = zipsByState.get(p.state) ?? [];
      list.push(p);
      zipsByState.set(p.state, list);
    }
  }
  return zipsByState.get(state) ?? [];
}

/**
 * Grid cell size in degrees (~11 km). Report locations are snapped to the
 * cell center before storage so no map dot points at a home (PRD §8).
 */
export const CELL_DEG = 0.1;

export function toCell(lat: number, lng: number): { cellLat: number; cellLng: number } {
  const snap = (v: number) => Math.round((Math.floor(v / CELL_DEG) * CELL_DEG + CELL_DEG / 2) * 1000) / 1000;
  return { cellLat: snap(lat), cellLng: snap(lng) };
}

/** Share of a service's national report volume expected from one state. */
export function stateShare(service: Service, state: string): number {
  const info = STATE_BY_CODE.get(state);
  if (!info) return 0;
  if (service.states.length === 0) return info.pop / TOTAL_POP;
  if (!service.states.includes(state)) return 0;
  const footprint = service.states.reduce((sum, c) => sum + (STATE_BY_CODE.get(c)?.pop ?? 0), 0);
  return footprint > 0 ? info.pop / footprint : 0;
}


/** Radius used for "near you" status (miles). */
export const NEARBY_MILES = 15;

const nearbyCache = new Map<string, string[]>();

/** ZIPs within NEARBY_MILES of a ZIP, including itself. */
export function nearbyZips(zip: string): string[] {
  let hit = nearbyCache.get(zip);
  if (!hit) {
    hit = lookupZip(zip) ? zipcodes.radius(zip, NEARBY_MILES).filter((z) => lookupZip(z)) : [];
    if (!hit.includes(zip) && lookupZip(zip)) hit.push(zip);
    nearbyCache.set(zip, hit);
  }
  return hit;
}
