"use client";

// One-tap crowd reporting (PRD §6.7).

import { useRef, useState } from "react";
import { PROBLEM_LABEL, type ProblemType } from "@/lib/types";
import { useLive } from "./LiveProvider";

export function ReportButton({ slug, name, problemTypes }: { slug: string; name: string; problemTypes: ProblemType[] }) {
  const { location, deviceId, toast } = useLive();
  const dialog = useRef<HTMLDialogElement>(null);
  const [zip, setZip] = useState("");
  const [problem, setProblem] = useState<ProblemType>(problemTypes[0]);
  const [comment, setComment] = useState("");
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState<string | null>(null);
  const [done, setDone] = useState<number | null>(null);

  const open = () => {
    setZip(location?.zip ?? "");
    setErr(null);
    setDone(null);
    dialog.current?.showModal();
  };

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    setBusy(true);
    setErr(null);
    try {
      const r = await fetch("/api/reports", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ service: slug, zip, problemType: problem, comment, deviceId }),
      });
      const body = await r.json();
      if (!r.ok) throw new Error(body.error);
      setDone(body.nearbyLastHour);
      setComment("");
      toast({ title: "Report received", body: `Thanks for reporting ${name}.`, level: "ok" });
    } catch (e) {
      setErr((e as Error).message);
    } finally {
      setBusy(false);
    }
  };

  return (
    <>
      <button className="btn btn-danger" onClick={open}>
        I have a problem with {name}
      </button>
      <dialog ref={dialog} className="modal" aria-labelledby="report-title">
        <form className="body stack" onSubmit={submit} method="dialog">
          <h2 id="report-title">Report a problem with {name}</h2>
          {done !== null ? (
            <>
              <p className="success">
                Thanks. {done > 1 ? `You and about ${done - 1} others nearby reported ${name} problems in the last hour.` : "Your report is counted."}
              </p>
              <div className="row">
                <span className="spacer" />
                <button type="button" className="btn" onClick={() => dialog.current?.close()}>
                  Done
                </button>
              </div>
            </>
          ) : (
            <>
              <fieldset style={{ border: 0, padding: 0, margin: 0 }}>
                <legend className="small" style={{ fontWeight: 500, marginBottom: 6 }}>
                  What's wrong?
                </legend>
                <div className="radio-grid">
                  {problemTypes.map((p) => (
                    <label key={p}>
                      <input type="radio" name="problem" value={p} checked={problem === p} onChange={() => setProblem(p)} />
                      <span>{PROBLEM_LABEL[p]}</span>
                    </label>
                  ))}
                </div>
              </fieldset>
              <label className="field">
                <span>ZIP code</span>
                <input className="input" inputMode="numeric" maxLength={5} required pattern="\d{5}" value={zip} onChange={(e) => setZip(e.target.value.replace(/\D/g, ""))} />
              </label>
              <label className="field">
                <span>Comment (optional)</span>
                <textarea className="input" maxLength={280} value={comment} onChange={(e) => setComment(e.target.value)} placeholder="e.g. Modem light blinking orange since 3pm" />
              </label>
              <p className="tiny">We store your ZIP and an approximate area, never your exact location. Comments are public.</p>
              {err && <div className="error" role="alert">{err}</div>}
              <div className="row">
                <span className="spacer" />
                <button type="button" className="btn" onClick={() => dialog.current?.close()}>
                  Cancel
                </button>
                <button className="btn btn-danger" disabled={busy || zip.length !== 5}>
                  Submit report
                </button>
              </div>
            </>
          )}
        </form>
      </dialog>
    </>
  );
}
