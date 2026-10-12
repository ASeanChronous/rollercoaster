"use client";

// App-wide client state: the user's location, a single live event stream,
// saved alert subscriptions, and in-app/browser notifications.

import { createContext, useCallback, useContext, useEffect, useMemo, useRef, useState, type ReactNode } from "react";
import type { StatusLevel } from "@/lib/types";

export interface Location {
  zip: string;
  city: string;
  state: string;
  stateName?: string;
  /** ZIP centroid (public data), used to center the map. Never the user's GPS position. */
  lat?: number;
  lng?: number;
}

export interface SavedSub {
  id: string;
  token: string;
  zip: string;
  services: string[];
}

interface Toast {
  id: string;
  title: string;
  body: string;
  level: StatusLevel;
}

interface LiveCtx {
  location: Location | null;
  setLocation: (l: Location | null) => void;
  /** Increments after each server recompute; use as a refetch dependency. */
  tick: number;
  subs: SavedSub[];
  addSub: (s: SavedSub) => void;
  removeSub: (id: string) => void;
  deviceId: string;
  toast: (t: Omit<Toast, "id">) => void;
}

const Ctx = createContext<LiveCtx | null>(null);

function read<T>(key: string, fallback: T): T {
  try {
    const raw = localStorage.getItem(key);
    return raw ? (JSON.parse(raw) as T) : fallback;
  } catch {
    return fallback;
  }
}

function write(key: string, value: unknown): void {
  try {
    localStorage.setItem(key, JSON.stringify(value));
  } catch {}
}

export function LiveProvider({ children }: { children: ReactNode }) {
  const [location, setLocationState] = useState<Location | null>(null);
  const [subs, setSubs] = useState<SavedSub[]>([]);
  const [tick, setTick] = useState(0);
  const [toasts, setToasts] = useState<Toast[]>([]);
  const [deviceId, setDeviceId] = useState("");

  useEffect(() => {
    setLocationState(read<Location | null>("rc.location", null));
    setSubs(read<SavedSub[]>("rc.subs", []));
    let id = read<string>("rc.device", "");
    if (!id) {
      id = crypto.randomUUID();
      write("rc.device", id);
    }
    setDeviceId(id);
  }, []);

  const setLocation = useCallback((l: Location | null) => {
    setLocationState(l);
    write("rc.location", l);
  }, []);

  const addSub = useCallback((s: SavedSub) => {
    setSubs((prev) => {
      const next = [...prev.filter((p) => p.id !== s.id), s];
      write("rc.subs", next);
      return next;
    });
  }, []);

  const removeSub = useCallback((id: string) => {
    setSubs((prev) => {
      const next = prev.filter((p) => p.id !== id);
      write("rc.subs", next);
      return next;
    });
  }, []);

  const toast = useCallback((t: Omit<Toast, "id">) => {
    const id = crypto.randomUUID();
    setToasts((prev) => [...prev.slice(-3), { ...t, id }]);
    setTimeout(() => setToasts((prev) => prev.filter((x) => x.id !== id)), 9000);
  }, []);

  const subIds = subs.map((s) => s.id).join(",");
  useEffect(() => {
    const es = new EventSource(`/api/stream${subIds ? `?subs=${encodeURIComponent(subIds)}` : ""}`);
    es.addEventListener("tick", () => setTick((n) => n + 1));
    es.addEventListener("alert", (e) => {
      const m = JSON.parse((e as MessageEvent).data) as { title: string; body: string; level: StatusLevel };
      toast({ title: m.title, body: m.body, level: m.level });
      if (typeof Notification !== "undefined" && Notification.permission === "granted" && document.visibilityState !== "visible") {
        try {
          new Notification(m.title, { body: m.body, tag: m.title });
        } catch {}
      }
    });
    return () => es.close();
  }, [subIds, toast]);

  const value = useMemo(
    () => ({ location, setLocation, tick, subs, addSub, removeSub, deviceId, toast }),
    [location, setLocation, tick, subs, addSub, removeSub, deviceId, toast],
  );

  return (
    <Ctx.Provider value={value}>
      {children}
      <div className="toasts" role="status" aria-live="polite">
        {toasts.map((t) => (
          <div key={t.id} className={`toast ${t.level}`}>
            <strong>{t.title}</strong>
            {t.body && <div className="muted small">{t.body}</div>}
          </div>
        ))}
      </div>
    </Ctx.Provider>
  );
}

export function useLive(): LiveCtx {
  const ctx = useContext(Ctx);
  if (!ctx) throw new Error("useLive must be used inside LiveProvider");
  return ctx;
}

/** Fetch JSON and refetch whenever the server recomputes (and when deps change). */
export function useLiveJson<T>(url: string | null): { data: T | null; error: string | null; loading: boolean } {
  const { tick } = useLive();
  const [data, setData] = useState<T | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const lastUrl = useRef<string | null>(null);

  useEffect(() => {
    if (!url) return;
    let cancelled = false;
    if (lastUrl.current !== url) {
      setLoading(true);
      lastUrl.current = url;
    }
    fetch(url)
      .then(async (r) => {
        const body = await r.json();
        if (!r.ok) throw new Error(body.error ?? `Request failed (${r.status})`);
        return body as T;
      })
      .then((d) => {
        if (!cancelled) {
          setData(d);
          setError(null);
        }
      })
      .catch((e: Error) => !cancelled && setError(e.message))
      .finally(() => !cancelled && setLoading(false));
    return () => {
      cancelled = true;
    };
  }, [url, tick]);

  return { data, error, loading };
}
