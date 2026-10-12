"use client";

import Link from "next/link";
import { useMemo, useState } from "react";
import { CATEGORY_LABEL, type Category, type StatusResult } from "@/lib/types";
import { Sparkline } from "./Sparkline";
import { StatusBadge } from "./StatusBadge";

export interface Summary {
  slug: string;
  name: string;
  category: Category;
  status: StatusResult;
  spark: number[];
}

const RANK = { problems: 2, possible: 1, ok: 0 } as const;

export function sortBySeverity(list: Summary[]): Summary[] {
  return [...list].sort((a, b) => RANK[b.status.level] - RANK[a.status.level] || b.status.ratio - a.status.ratio || b.status.current - a.status.current);
}

/** Live overview by provider with category filters (PRD §6.5). */
export function ServiceList({ services, query = "", initialCategory }: { services: Summary[]; query?: string; initialCategory?: Category }) {
  const [category, setCategory] = useState<Category | "all">(initialCategory ?? "all");
  const [q, setQ] = useState("");
  const categories = useMemo(() => [...new Set(services.map((s) => s.category))], [services]);
  const shown = sortBySeverity(
    services.filter((s) => (category === "all" || s.category === category) && (!q || s.name.toLowerCase().includes(q.toLowerCase()))),
  );

  return (
    <div className="stack">
      <div className="row">
        <div className="chips" role="group" aria-label="Filter by category">
          <button className="chip" aria-pressed={category === "all"} onClick={() => setCategory("all")}>
            All
          </button>
          {categories.map((c) => (
            <button key={c} className="chip" aria-pressed={category === c} onClick={() => setCategory(c)}>
              {CATEGORY_LABEL[c]}
            </button>
          ))}
        </div>
        <span className="spacer" />
        <label className="sr-only" htmlFor="svc-filter">
          Find a service
        </label>
        <input id="svc-filter" className="input" style={{ maxWidth: 220 }} placeholder="Find a service" value={q} onChange={(e) => setQ(e.target.value)} />
      </div>
      <div className="card card-tight">
        {shown.length === 0 ? (
          <div className="empty">No services match.</div>
        ) : (
          <ul className="svc-list">
            {shown.map((s) => (
              <li key={s.slug}>
                <Link className="svc-row" href={`/status/${s.slug}${query}`}>
                  <div>
                    <div className="name">{s.name}</div>
                    <div className="meta">
                      {CATEGORY_LABEL[s.category]} · {Math.round(s.status.current)} reports in 15 min
                      {s.status.level !== "ok" && s.status.ratio >= 1.5 ? ` · ${s.status.ratio}× normal` : ""}
                    </div>
                  </div>
                  <div className="right">
                    <Sparkline values={s.spark} />
                    <StatusBadge level={s.status.level} />
                  </div>
                </Link>
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  );
}
