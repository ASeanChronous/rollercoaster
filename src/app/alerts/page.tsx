"use client";

import { useSearchParams } from "next/navigation";
import { Suspense, useEffect, useState } from "react";
import { useLive, type SavedSub } from "@/components/LiveProvider";
import { StatusBadge } from "@/components/StatusBadge";
import { getService, SERVICES } from "@/lib/services";
import { CATEGORY_LABEL, type Category, type StatusLevel } from "@/lib/types";

export default function AlertsPage() {
  return (
    <Suspense>
      <Alerts />
    </Suspense>
  );
}

function Alerts() {
  const params = useSearchParams();
  const { location, subs, addSub, removeSub } = useLive();
  const [zip, setZip] = useState("");
  const [selected, setSelected] = useState<Set<string>>(new Set());
  const [email, setEmail] = useState("");
  const [browser, setBrowser] = useState(true);
  const [minLevel, setMinLevel] = useState<"possible" | "problems">("possible");
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState<string | null>(null);
  const [ok, setOk] = useState<string | null>(null);

  useEffect(() => {
    if (location && !zip) setZip(location.zip);
  }, [location, zip]);

  useEffect(() => {
    const s = params.get("service");
    if (s && getService(s)) setSelected((prev) => new Set(prev).add(s));
  }, [params]);

  const toggle = (slug: string) =>
    setSelected((prev) => {
      const next = new Set(prev);
      if (next.has(slug)) next.delete(slug);
      else next.add(slug);
      return next;
    });

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    setErr(null);
    setOk(null);
    if (browser && typeof Notification !== "undefined" && Notification.permission === "default") {
      await Notification.requestPermission().catch(() => undefined);
    }
    setBusy(true);
    try {
      const r = await fetch("/api/alerts", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ zip, services: [...selected], email, browser, minLevel }),
      });
      const body = await r.json();
      if (!r.ok) throw new Error(body.error);
      addSub({ id: body.id, token: body.token, zip: body.zip, services: body.services });
      setOk(`Alerts are on for ${body.services.length} service${body.services.length > 1 ? "s" : ""} near ${body.zip}.`);
      setSelected(new Set());
    } catch (e) {
      setErr((e as Error).message);
    } finally {
      setBusy(false);
    }
  };

  const categories = Object.keys(CATEGORY_LABEL) as Category[];

  return (
    <div className="stack">
      <div>
        <h1>Outage alerts</h1>
        <p className="muted">Get told when a service you rely on has problems near you, and again when it&apos;s fixed.</p>
      </div>

      <form className="card stack" onSubmit={submit}>
        <h2>New alert</h2>
        <div className="row" style={{ alignItems: "flex-end" }}>
          <label className="field" style={{ maxWidth: 160 }}>
            <span>ZIP code</span>
            <input className="input" inputMode="numeric" maxLength={5} required pattern="\d{5}" value={zip} onChange={(e) => setZip(e.target.value.replace(/\D/g, ""))} />
          </label>
          <label className="field" style={{ flex: "1 1 240px" }}>
            <span>Email (optional)</span>
            <input className="input" type="email" value={email} onChange={(e) => setEmail(e.target.value)} placeholder="you@example.com" />
          </label>
          <label className="field" style={{ maxWidth: 220 }}>
            <span>Alert me on</span>
            <select className="input" value={minLevel} onChange={(e) => setMinLevel(e.target.value as "possible" | "problems")}>
              <option value="possible">Possible problems or worse</option>
              <option value="problems">Confirmed problems only</option>
            </select>
          </label>
        </div>
        <label className="row small" style={{ gap: 8 }}>
          <input type="checkbox" checked={browser} onChange={(e) => setBrowser(e.target.checked)} />
          Browser notifications while Rollercoaster is open in a tab
        </label>

        <fieldset style={{ border: 0, padding: 0, margin: 0 }}>
          <legend className="small" style={{ fontWeight: 500, marginBottom: 6 }}>
            Services ({selected.size} selected)
          </legend>
          <div className="stack">
            {categories.map((c) => (
              <div key={c}>
                <div className="tiny" style={{ marginBottom: 4 }}>
                  {CATEGORY_LABEL[c]}
                </div>
                <div className="chips">
                  {SERVICES.filter((s) => s.category === c).map((s) => (
                    <button type="button" key={s.slug} className="chip" aria-pressed={selected.has(s.slug)} onClick={() => toggle(s.slug)}>
                      {s.name}
                    </button>
                  ))}
                </div>
              </div>
            ))}
          </div>
        </fieldset>

        {err && <div className="error" role="alert">{err}</div>}
        {ok && <div className="success" role="status">{ok}</div>}
        <div className="row">
          <span className="tiny">Email delivery runs in development mode: messages are logged on the server, not sent.</span>
          <span className="spacer" />
          <button className="btn btn-primary" disabled={busy || selected.size === 0 || zip.length !== 5}>
            Turn on alerts
          </button>
        </div>
      </form>

      <div className="stack">
        <h2>Your alerts</h2>
        {subs.length === 0 ? <div className="card empty">No alerts yet.</div> : subs.map((s) => <SubCard key={s.id} sub={s} onRemove={() => removeSub(s.id)} />)}
      </div>
    </div>
  );
}

interface Msg {
  id: string;
  kind: "opened" | "escalated" | "resolved";
  title: string;
  body: string;
  level: StatusLevel;
  createdAt: number;
}

function SubCard({ sub, onRemove }: { sub: SavedSub; onRemove: () => void }) {
  const { tick } = useLive();
  const [messages, setMessages] = useState<Msg[] | null>(null);
  const [gone, setGone] = useState(false);

  useEffect(() => {
    fetch(`/api/alerts?id=${sub.id}&token=${sub.token}`)
      .then(async (r) => {
        if (r.status === 404) return setGone(true);
        const body = await r.json();
        setMessages(body.messages);
      })
      .catch(() => undefined);
  }, [sub.id, sub.token, tick]);

  const remove = async () => {
    await fetch(`/api/alerts?id=${sub.id}&token=${sub.token}`, { method: "DELETE" }).catch(() => undefined);
    onRemove();
  };

  return (
    <div className="card stack">
      <div className="row">
        <div>
          <strong>Near {sub.zip}</strong>
          <div className="small muted">{sub.services.map((s) => getService(s)?.name ?? s).join(", ")}</div>
        </div>
        <span className="spacer" />
        <button className="btn btn-sm" onClick={remove}>
          Remove
        </button>
      </div>
      {gone ? (
        <p className="small muted">This alert is no longer on the server (the demo server restarted). Remove it and set it up again.</p>
      ) : messages && messages.length > 0 ? (
        <ul className="tips" style={{ listStyle: "none", padding: 0 }}>
          {messages.slice(0, 10).map((m) => (
            <li key={m.id} className="row" style={{ alignItems: "flex-start" }}>
              <StatusBadge level={m.level} />
              <div style={{ flex: 1, minWidth: 200 }}>
                <div>{m.title}</div>
                <div className="small muted">{m.body}</div>
                <div className="tiny">{new Date(m.createdAt).toLocaleString("en-US", { weekday: "short", hour: "numeric", minute: "2-digit" })}</div>
              </div>
            </li>
          ))}
        </ul>
      ) : (
        <p className="small muted">No alerts sent yet. Everything has been normal.</p>
      )}
    </div>
  );
}
