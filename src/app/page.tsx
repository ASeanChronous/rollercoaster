"use client";

import Link from "next/link";
import { useState } from "react";
import { LocationBar } from "@/components/LocationBar";
import { useLive, useLiveJson } from "@/components/LiveProvider";
import { ServiceList, sortBySeverity, type Summary } from "@/components/ServiceList";
import { StatusBadge } from "@/components/StatusBadge";

export default function Home() {
  const { location } = useLive();
  const [scope, setScope] = useState<"near" | "us">("near");
  const near = location && scope === "near";
  const query = near ? `?zip=${location.zip}` : "";
  const { data, error } = useLiveJson<{ services: Summary[] }>(`/api/services${query}`);
  const national = useLiveJson<{ services: Summary[] }>("/api/services");

  const issues = sortBySeverity((national.data?.services ?? []).filter((s) => s.status.level !== "ok"));
  const nearIssues = near ? sortBySeverity((data?.services ?? []).filter((s) => s.status.level !== "ok")) : [];
  const problems = issues.filter((s) => s.status.level === "problems").length;

  return (
    <div className="stack">
      <div>
        <h1>Is it down right now?</h1>
        <p className="muted">Live status for internet, mobile, TV, streaming, gaming, banking and power, combined from several outage trackers and user reports.</p>
      </div>

      <div className="card">
        <LocationBar />
      </div>

      {near && data && (
        <div className={`callout${nearIssues.some((s) => s.status.level === "problems") ? " bad" : ""}`}>
          {nearIssues.length === 0 ? (
            <span>
              <StatusBadge level="ok" /> &nbsp;Everything looks normal near {location.city}.
            </span>
          ) : (
            <div className="stack">
              <strong>
                {nearIssues.length} service{nearIssues.length > 1 ? "s" : ""} with reported issues near {location.city}
              </strong>
              <div className="row">
                {nearIssues.slice(0, 6).map((s) => (
                  <Link key={s.slug} href={`/status/${s.slug}${query}`} className="row" style={{ gap: 6 }}>
                    <StatusBadge level={s.status.level} /> {s.name}
                  </Link>
                ))}
              </div>
            </div>
          )}
        </div>
      )}

      <div className="kpis">
        <div className="kpi">
          <div className="v">{national.data ? problems : "–"}</div>
          <div className="l">Services with problems nationwide</div>
        </div>
        <div className="kpi">
          <div className="v">{national.data ? issues.length - problems : "–"}</div>
          <div className="l">With possible problems</div>
        </div>
        <div className="kpi">
          <div className="v">{national.data ? Math.round(national.data.services.reduce((a, s) => a + s.status.current, 0)).toLocaleString() : "–"}</div>
          <div className="l">Reports in the last 15 min</div>
        </div>
        <div className="kpi">
          <div className="v">{national.data?.services.length ?? "–"}</div>
          <div className="l">Services monitored</div>
        </div>
      </div>

      <div className="stack">
        <div className="row">
          <h2 style={{ margin: 0 }}>{near ? `Services near ${location.city}, ${location.state}` : "All services nationwide"}</h2>
          <span className="spacer" />
          {location && (
            <div className="chips" role="group" aria-label="Scope">
              <button className="chip" aria-pressed={scope === "near"} onClick={() => setScope("near")}>
                Near me
              </button>
              <button className="chip" aria-pressed={scope === "us"} onClick={() => setScope("us")}>
                Nationwide
              </button>
            </div>
          )}
        </div>
        {error && <div className="error">{error}</div>}
        {data ? <ServiceList services={data.services} query={query} /> : <div className="card empty">Loading live status…</div>}
      </div>
    </div>
  );
}
