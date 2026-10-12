"use client";

import Link from "next/link";
import { useLiveJson } from "@/components/LiveProvider";
import { ServiceList, sortBySeverity, type Summary } from "@/components/ServiceList";
import { StatusBadge } from "@/components/StatusBadge";

export function StateDetail({ code, name }: { code: string; name: string }) {
  const { data, error } = useLiveJson<{ services: Summary[] }>(`/api/services?state=${code}`);
  const issues = sortBySeverity((data?.services ?? []).filter((s) => s.status.level !== "ok"));
  const worst = issues[0]?.status.level ?? "ok";

  return (
    <div className="stack">
      <div className="tiny">
        <Link href="/states">States</Link> / {name}
      </div>
      <div className="row">
        <h1 style={{ margin: 0 }}>Outages in {name}</h1>
        {data && <StatusBadge level={worst} large />}
      </div>
      {error && <div className="error">{error}</div>}
      {data && (
        <div className="kpis">
          <div className="kpi">
            <div className="v">{issues.filter((s) => s.status.level === "problems").length}</div>
            <div className="l">Services with problems</div>
          </div>
          <div className="kpi">
            <div className="v">{issues.filter((s) => s.status.level === "possible").length}</div>
            <div className="l">Possible problems</div>
          </div>
          <div className="kpi">
            <div className="v">{Math.round(data.services.reduce((a, s) => a + s.status.current, 0))}</div>
            <div className="l">Reports in the last 15 min</div>
          </div>
          <div className="kpi">
            <div className="v">{data.services.length}</div>
            <div className="l">Services available here</div>
          </div>
        </div>
      )}
      {issues.length > 0 && (
        <div className="card">
          <h2>Top outages in {name}</h2>
          <ul className="reasons" style={{ color: "var(--text)" }}>
            {issues.slice(0, 5).map((s) => (
              <li key={s.slug}>
                <Link href={`/status/${s.slug}?state=${code}`}>{s.name}</Link>: {s.status.reasons[0]}
              </li>
            ))}
          </ul>
        </div>
      )}
      <p>
        <Link href="/map">See {name} on the outage map →</Link>
      </p>
      {data ? <ServiceList services={data.services} query={`?state=${code}`} /> : <div className="card empty">Loading…</div>}
    </div>
  );
}
