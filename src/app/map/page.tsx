"use client";

import dynamic from "next/dynamic";
import Link from "next/link";
import { useState } from "react";
import { useLive, useLiveJson } from "@/components/LiveProvider";
import type { Cell, StateLevel } from "@/components/OutageMap";
import { StatusBadge } from "@/components/StatusBadge";
import { SERVICES } from "@/lib/services";
import { CATEGORY_LABEL, type Category } from "@/lib/types";

const OutageMap = dynamic(() => import("@/components/OutageMap"), {
  ssr: false,
  loading: () => <div className="empty">Loading map…</div>,
});

const WINDOWS = [
  { m: 60, label: "Last hour" },
  { m: 360, label: "6 hours" },
  { m: 1440, label: "24 hours" },
];

export default function MapPage() {
  const { location } = useLive();
  const [mode, setMode] = useState<"dots" | "states">("dots");
  const [minutes, setMinutes] = useState(60);
  const [service, setService] = useState("");
  const [category, setCategory] = useState<Category | "">("");

  const qs = new URLSearchParams({ minutes: String(minutes) });
  if (service) qs.set("service", service);
  else if (category) qs.set("category", category);
  const { data, error } = useLiveJson<{ cells: Cell[]; states: StateLevel[] }>(`/api/map?${qs}`);

  const affected = (data?.states ?? []).filter((s) => s.level !== "ok").sort((a, b) => b.problems - a.problems || b.possible - a.possible);
  const center: [number, number] = location?.lat && location.lng ? [location.lat, location.lng] : [39.5, -98.35];
  const zoom = location?.lat ? 8 : 4;

  return (
    <div className="stack">
      <div>
        <h1>Live outage map</h1>
        <p className="muted">Red dots show areas with 5 or more reports. Dots are grouped into areas about 7 miles across, so no dot points to a home.</p>
      </div>

      <div className="row">
        <div className="chips" role="group" aria-label="Map layer">
          <button className="chip" aria-pressed={mode === "dots"} onClick={() => setMode("dots")}>
            Reports
          </button>
          <button className="chip" aria-pressed={mode === "states"} onClick={() => setMode("states")}>
            State status
          </button>
        </div>
        <div className="chips" role="group" aria-label="Time window">
          {WINDOWS.map((w) => (
            <button key={w.m} className="chip" aria-pressed={minutes === w.m} onClick={() => setMinutes(w.m)}>
              {w.label}
            </button>
          ))}
        </div>
        <span className="spacer" />
        <label className="sr-only" htmlFor="map-cat">
          Category
        </label>
        <select id="map-cat" className="input" style={{ maxWidth: 180 }} value={category} onChange={(e) => { setCategory(e.target.value as Category | ""); setService(""); }}>
          <option value="">All categories</option>
          {Object.entries(CATEGORY_LABEL).map(([k, v]) => (
            <option key={k} value={k}>
              {v}
            </option>
          ))}
        </select>
        <label className="sr-only" htmlFor="map-svc">
          Service
        </label>
        <select id="map-svc" className="input" style={{ maxWidth: 220 }} value={service} onChange={(e) => setService(e.target.value)}>
          <option value="">All services</option>
          {SERVICES.filter((s) => !category || s.category === category).map((s) => (
            <option key={s.slug} value={s.slug}>
              {s.name}
            </option>
          ))}
        </select>
      </div>

      {error && <div className="error">{error}</div>}

      <div className="map-wrap">
        <OutageMap
          key={center.join(",")}
          mode={mode}
          cells={data?.cells ?? []}
          states={data?.states ?? []}
          center={center}
          zoom={zoom}
        />
      </div>

      <div className="map-legend">
        {mode === "dots" ? (
          <span>
            <span className="dot" />
            Reported outages (bigger = more reports)
          </span>
        ) : (
          <>
            <StatusBadge level="ok" />
            <StatusBadge level="possible" />
            <StatusBadge level="problems" />
          </>
        )}
        <span className="spacer" />
        <span>{data ? `${data.cells.length} areas with reports` : ""}</span>
      </div>

      <div className="card">
        <h2>States with reported issues</h2>
        {affected.length === 0 ? (
          <p className="muted">No state has reported issues right now.</p>
        ) : (
          <table className="data">
            <thead>
              <tr>
                <th>State</th>
                <th>Status</th>
                <th className="num">Problems</th>
                <th className="num">Possible</th>
              </tr>
            </thead>
            <tbody>
              {affected.map((s) => (
                <tr key={s.state}>
                  <td>
                    <Link href={`/states/${s.state}`}>{s.name}</Link>
                  </td>
                  <td>
                    <StatusBadge level={s.level} />
                  </td>
                  <td className="num">{s.problems}</td>
                  <td className="num">{s.possible}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}

