// Personalized alerts (PRD §6.6). One alert thread per incident: an opening
// alert, an escalation update if it gets worse, and a "resolved" notice with
// the outage duration (which the credit helper can use later).

import { randomUUID } from "node:crypto";
import { levelAtLeast } from "./detection";
import { getService } from "./services";
import { STATUS_LABEL, type StatusLevel, type StatusResult } from "./types";

export interface Subscription {
  id: string;
  /** Secret needed to manage or delete the subscription. */
  token: string;
  email?: string;
  zip: string;
  serviceSlugs: string[];
  minLevel: Exclude<StatusLevel, "ok">;
  /** Deliver to the browser while a Rollercoaster tab is open. */
  browser: boolean;
  createdAt: number;
}

export type AlertKind = "opened" | "escalated" | "resolved";

export interface AlertMessage {
  id: string;
  subscriptionId: string;
  kind: AlertKind;
  serviceSlug: string;
  zip: string;
  level: StatusLevel;
  title: string;
  body: string;
  createdAt: number;
  durationMs?: number;
}

export interface EmailTransport {
  send(to: string, subject: string, text: string): Promise<void>;
}

/** Development transport: logs and keeps an outbox. Swap for SES/Postmark/etc. in production. */
export class ConsoleEmailTransport implements EmailTransport {
  readonly outbox: { to: string; subject: string; text: string; at: number }[] = [];
  async send(to: string, subject: string, text: string): Promise<void> {
    this.outbox.push({ to, subject, text, at: Date.now() });
    if (this.outbox.length > 200) this.outbox.shift();
    console.log(`[email] to=${to} subject="${subject}"`);
  }
}

interface ThreadState {
  level: StatusLevel;
  openedAt?: number;
}

export class AlertManager {
  private readonly subs = new Map<string, Subscription>();
  private readonly threads = new Map<string, ThreadState>();
  readonly recent: AlertMessage[] = [];

  constructor(
    private readonly email: EmailTransport,
    private readonly onMessage: (m: AlertMessage) => void,
  ) {}

  subscribe(input: Omit<Subscription, "id" | "token" | "createdAt">, now: number): Subscription {
    const sub: Subscription = { ...input, id: randomUUID(), token: randomUUID(), createdAt: now };
    this.subs.set(sub.id, sub);
    return sub;
  }

  get(id: string, token: string): Subscription | undefined {
    const s = this.subs.get(id);
    return s && s.token === token ? s : undefined;
  }

  unsubscribe(id: string, token: string): boolean {
    if (!this.get(id, token)) return false;
    this.subs.delete(id);
    for (const k of this.threads.keys()) if (k.startsWith(`${id}|`)) this.threads.delete(k);
    return true;
  }

  count(): number {
    return this.subs.size;
  }

  messagesFor(id: string): AlertMessage[] {
    return this.recent.filter((m) => m.subscriptionId === id);
  }

  /** Compare each subscription's current status to its last notified state. */
  evaluate(now: number, statusAt: (slug: string, zip: string) => StatusResult): AlertMessage[] {
    const sent: AlertMessage[] = [];
    for (const sub of this.subs.values()) {
      for (const slug of sub.serviceSlugs) {
        const key = `${sub.id}|${slug}`;
        const prev = this.threads.get(key) ?? { level: "ok" as StatusLevel };
        const status = statusAt(slug, sub.zip);
        const qualifies = levelAtLeast(status.level, sub.minLevel);
        let kind: AlertKind | undefined;
        if (!prev.openedAt && qualifies) kind = "opened";
        else if (prev.openedAt && status.level === "problems" && prev.level === "possible") kind = "escalated";
        else if (prev.openedAt && status.level === "ok") kind = "resolved";

        if (kind) {
          const msg = this.compose(sub, slug, kind, status, now, prev.openedAt);
          sent.push(msg);
          this.deliver(sub, msg);
        }
        const openedAt = kind === "resolved" ? undefined : (prev.openedAt ?? (kind === "opened" ? now : undefined));
        this.threads.set(key, { level: status.level, openedAt });
      }
    }
    return sent;
  }

  private compose(sub: Subscription, slug: string, kind: AlertKind, status: StatusResult, now: number, openedAt?: number): AlertMessage {
    const name = getService(slug)?.name ?? slug;
    const durationMs = kind === "resolved" && openedAt ? now - openedAt : undefined;
    const title =
      kind === "resolved"
        ? `${name} is back to normal near ${sub.zip}`
        : `${name}: ${STATUS_LABEL[status.level]} near ${sub.zip}`;
    const lines =
      kind === "resolved"
        ? [`Reports have returned to normal.${durationMs ? ` The problem lasted about ${formatDuration(durationMs)}.` : ""}`]
        : [
            status.reasons[0] ?? "",
            status.officialMessage ? `Provider update: ${status.officialMessage}` : "",
            status.etaAt ? `Estimated fix: ${new Date(status.etaAt).toLocaleTimeString("en-US", { hour: "numeric", minute: "2-digit" })}` : "",
          ];
    return {
      id: randomUUID(), subscriptionId: sub.id, kind, serviceSlug: slug, zip: sub.zip, level: status.level,
      title, body: lines.filter(Boolean).join(" "), createdAt: now, durationMs,
    };
  }

  private deliver(sub: Subscription, msg: AlertMessage): void {
    this.recent.push(msg);
    if (this.recent.length > 1000) this.recent.shift();
    if (sub.browser) this.onMessage(msg);
    if (sub.email) {
      const unsub = `Manage or stop these alerts at /alerts?id=${sub.id}`;
      this.email.send(sub.email, msg.title, `${msg.body}\n\n${unsub}`).catch((e) => console.error("[email] failed", e));
    }
  }
}

export function formatDuration(ms: number): string {
  const min = Math.round(ms / 60_000);
  if (min < 60) return `${min} min`;
  const h = Math.floor(min / 60);
  const m = min % 60;
  return m ? `${h} hr ${m} min` : `${h} hr`;
}
