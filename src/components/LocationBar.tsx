"use client";

// GPS detection, ZIP search and state selection (PRD §6.4).

import { useRouter } from "next/navigation";
import { useState } from "react";
import { STATES } from "@/lib/geo-states";
import { useLive, type Location } from "./LiveProvider";

async function resolve(query: string): Promise<Location> {
  const r = await fetch(`/api/geo?${query}`);
  const body = await r.json();
  if (!r.ok) throw new Error(body.error);
  return { zip: body.zip, city: body.city, state: body.state, stateName: body.stateName, lat: body.lat, lng: body.lng };
}

export function LocationBar() {
  const { location, setLocation } = useLive();
  const router = useRouter();
  const [zip, setZip] = useState("");
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState<string | null>(null);

  const submitZip = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!/^\d{5}$/.test(zip.trim())) return setErr("Enter a 5-digit ZIP code.");
    setBusy(true);
    setErr(null);
    try {
      setLocation(await resolve(`zip=${zip.trim()}`));
      setZip("");
    } catch (e) {
      setErr((e as Error).message);
    } finally {
      setBusy(false);
    }
  };

  const useGps = () => {
    if (!navigator.geolocation) return setErr("Location isn't available in this browser. Enter your ZIP instead.");
    setBusy(true);
    setErr(null);
    navigator.geolocation.getCurrentPosition(
      async (pos) => {
        try {
          // Only the matched ZIP is kept; the coordinates are discarded.
          setLocation(await resolve(`lat=${pos.coords.latitude.toFixed(3)}&lng=${pos.coords.longitude.toFixed(3)}`));
        } catch (e) {
          setErr((e as Error).message);
        } finally {
          setBusy(false);
        }
      },
      () => {
        setBusy(false);
        setErr("We couldn't get your location. Enter your ZIP instead.");
      },
      { enableHighAccuracy: false, timeout: 10_000, maximumAge: 600_000 },
    );
  };

  return (
    <div className="stack">
      <div className="locbar">
        <div style={{ minWidth: 0 }}>
          <div className="tiny">Your location</div>
          <div style={{ fontWeight: 600 }}>
            {location ? `${location.city}, ${location.state} ${location.zip}` : "Not set"}
            {location && (
              <button className="btn btn-sm" style={{ marginLeft: 8 }} onClick={() => setLocation(null)}>
                Clear
              </button>
            )}
          </div>
        </div>
        <span className="spacer" />
        <button className="btn" onClick={useGps} disabled={busy}>
          <svg width="16" height="16" viewBox="0 0 16 16" aria-hidden="true">
            <circle cx="8" cy="8" r="3" fill="currentColor" />
            <circle cx="8" cy="8" r="6" stroke="currentColor" strokeWidth="1.5" fill="none" />
          </svg>
          Use my location
        </button>
        <form onSubmit={submitZip} role="search" aria-label="Search by ZIP code">
          <label className="sr-only" htmlFor="zip-input">
            ZIP code
          </label>
          <input
            id="zip-input"
            className="input"
            inputMode="numeric"
            pattern="\d{5}"
            maxLength={5}
            placeholder="ZIP code"
            value={zip}
            onChange={(e) => setZip(e.target.value.replace(/\D/g, ""))}
          />
          <button className="btn btn-primary" disabled={busy}>
            Check
          </button>
        </form>
        <label className="sr-only" htmlFor="state-select">
          Choose a state
        </label>
        <select id="state-select" className="input" value="" onChange={(e) => e.target.value && router.push(`/states/${e.target.value}`)}>
          <option value="">Browse by state…</option>
          {STATES.map((s) => (
            <option key={s.code} value={s.code}>
              {s.name}
            </option>
          ))}
        </select>
      </div>
      {err && <div className="error" role="alert">{err}</div>}
    </div>
  );
}
