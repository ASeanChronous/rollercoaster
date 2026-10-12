"use client";

import Link from "next/link";
import { useLiveJson } from "@/components/LiveProvider";
import type { StateLevel } from "@/components/OutageMap";
import { StatusBadge } from "@/components/StatusBadge";

export default function StatesPage() {
  const { data, error } = useLiveJson<{ states: StateLevel[] }>("/api/states");
  return (
    <div className="stack">
      <div>
        <h1>Outages by state</h1>
        <p className="muted">The worst current status across every service tracked in each state.</p>
      </div>
      {error && <div className="error">{error}</div>}
      {!data ? (
        <div className="card empty">Loading…</div>
      ) : (
        <div className="states-grid">
          {data.states.map((s) => (
            <Link key={s.state} href={`/states/${s.state}`} className="state-tile">
              <span className="n">{s.name}</span>
              <StatusBadge level={s.level} />
              <span className="tiny">
                {s.problems + s.possible === 0 ? "All services normal" : `${s.problems} problems · ${s.possible} possible`}
              </span>
            </Link>
          ))}
        </div>
      )}
    </div>
  );
}
