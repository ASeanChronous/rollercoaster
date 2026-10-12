"use client";

// Live outage map (PRD §6.3): red dots for aggregated report cells, or a
// state-by-state status layer. Loaded client-side only (Leaflet needs `window`).

import "leaflet/dist/leaflet.css";
import type { Feature, FeatureCollection, Geometry } from "geojson";
import type { PathOptions } from "leaflet";
import Link from "next/link";
import { useMemo } from "react";
import { CircleMarker, GeoJSON, MapContainer, Popup, TileLayer, Tooltip } from "react-leaflet";
import { feature } from "topojson-client";
import type { GeometryCollection, Topology } from "topojson-specification";
import statesTopo from "us-atlas/states-10m.json";
import type { StatusLevel } from "@/lib/types";

export interface Cell {
  lat: number;
  lng: number;
  count: number;
  top: { slug: string; name: string; count: number }[];
}

export interface StateLevel {
  state: string;
  name: string;
  fips: string;
  level: StatusLevel;
  problems: number;
  possible: number;
}

const FILL: Record<StatusLevel, string> = { ok: "#0ca30c", possible: "#fab219", problems: "#d03b3b" };

const topo = statesTopo as unknown as Topology<{ states: GeometryCollection }>;
const STATE_SHAPES = feature(topo, topo.objects.states) as unknown as FeatureCollection<Geometry, { name: string }>;

export default function OutageMap({
  mode,
  cells,
  states,
  center,
  zoom,
}: {
  mode: "dots" | "states";
  cells: Cell[];
  states: StateLevel[];
  center: [number, number];
  zoom: number;
}) {
  const byFips = useMemo(() => new Map(states.map((s) => [s.fips, s])), [states]);
  const max = Math.max(1, ...cells.map((c) => c.count));
  // Re-key the GeoJSON layer when levels change so styles refresh.
  const statesKey = states.map((s) => s.level[0]).join("");

  return (
    <MapContainer center={center} zoom={zoom} minZoom={3} maxZoom={12} style={{ height: "100%", width: "100%" }} worldCopyJump>
      <TileLayer
        attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
        url="https://tile.openstreetmap.org/{z}/{x}/{y}.png"
      />
      {mode === "states" && (
        <GeoJSON
          key={statesKey}
          data={STATE_SHAPES}
          style={(f?: Feature<Geometry, { name: string }>): PathOptions => {
            const s = f ? byFips.get(String(f.id)) : undefined;
            return { color: "#ffffff", weight: 1, fillColor: FILL[s?.level ?? "ok"], fillOpacity: s?.level === "ok" ? 0.15 : 0.5 };
          }}
          onEachFeature={(f, layer) => {
            const s = byFips.get(String(f.id));
            if (!s) return;
            const label = s.level === "ok" ? "No problems" : `${s.problems} with problems, ${s.possible} possible`;
            layer.bindTooltip(`<strong>${s.name}</strong><br/>${label}`, { sticky: true });
            layer.on("click", () => (window.location.href = `/states/${s.state}`));
          }}
        />
      )}
      {mode === "dots" && (
        // State outlines under the dots, so the map still reads if tiles fail to load.
        <GeoJSON data={STATE_SHAPES} interactive={false} style={{ color: "#8a8983", weight: 0.8, fill: false }} />
      )}
      {mode === "dots" &&
        cells.map((c) => (
          <CircleMarker
            key={`${c.lat},${c.lng}`}
            center={[c.lat, c.lng]}
            radius={5 + 17 * Math.sqrt(c.count / max)}
            pathOptions={{ color: "#ffffff", weight: 1.5, fillColor: "#d03b3b", fillOpacity: 0.65 }}
          >
            <Tooltip>{c.count} reports</Tooltip>
            <Popup>
              <strong>{c.count} reports in this area</strong>
              <ul style={{ margin: "6px 0 0", paddingLeft: 16 }}>
                {c.top.map((t) => (
                  <li key={t.slug}>
                    <Link href={`/status/${t.slug}`}>{t.name}</Link>: {t.count}
                  </li>
                ))}
              </ul>
            </Popup>
          </CircleMarker>
        ))}
    </MapContainer>
  );
}
