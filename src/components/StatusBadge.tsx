import { STATUS_LABEL, type StatusLevel } from "@/lib/types";

/** Status is always icon + label + color, never color alone (PRD §6.15). */
export function StatusIcon({ level, size = 14 }: { level: StatusLevel; size?: number }) {
  const common = { width: size, height: size, viewBox: "0 0 16 16", "aria-hidden": true } as const;
  if (level === "ok") {
    return (
      <svg {...common}>
        <circle cx="8" cy="8" r="7" fill="var(--good)" />
        <path d="M4.5 8.2 7 10.5l4.5-5" stroke="#fff" strokeWidth="2" fill="none" strokeLinecap="round" strokeLinejoin="round" />
      </svg>
    );
  }
  if (level === "possible") {
    return (
      <svg {...common}>
        <path d="M8 1.2 15.2 14H.8Z" fill="var(--warn)" />
        <path d="M8 5.5v4" stroke="#3a2a00" strokeWidth="1.8" strokeLinecap="round" />
        <circle cx="8" cy="11.8" r="1" fill="#3a2a00" />
      </svg>
    );
  }
  return (
    <svg {...common}>
      <circle cx="8" cy="8" r="7" fill="var(--bad)" />
      <path d="M5.2 5.2l5.6 5.6M10.8 5.2l-5.6 5.6" stroke="#fff" strokeWidth="2" strokeLinecap="round" />
    </svg>
  );
}

export function StatusBadge({ level, large }: { level: StatusLevel; large?: boolean }) {
  return (
    <span className={`badge badge-${level}${large ? " badge-lg" : ""}`}>
      <StatusIcon level={level} size={large ? 18 : 14} />
      {STATUS_LABEL[level]}
    </span>
  );
}
