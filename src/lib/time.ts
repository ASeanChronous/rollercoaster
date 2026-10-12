// Coarse local-time helpers. Baselines only need the local hour, so a fixed
// standard-time offset per state is accurate enough (DST shifts it by one hour).

const OFFSETS: Record<string, number> = {
  HI: -10, AK: -9,
  CA: -8, NV: -8, OR: -8, WA: -8,
  AZ: -7, CO: -7, ID: -7, MT: -7, NM: -7, UT: -7, WY: -7,
  AL: -6, AR: -6, IL: -6, IA: -6, KS: -6, LA: -6, MN: -6, MS: -6, MO: -6, NE: -6,
  ND: -6, OK: -6, SD: -6, TN: -6, TX: -6, WI: -6,
};

/** Hours from UTC for a state; Eastern for anything unlisted and for the nation. */
export function utcOffset(state?: string): number {
  return (state ? OFFSETS[state] : undefined) ?? -5;
}

export function localHourAndDay(ts: number, state?: string): { hour: number; day: number } {
  const d = new Date(ts + utcOffset(state) * 3_600_000);
  return { hour: d.getUTCHours(), day: d.getUTCDay() };
}

export const MINUTE = 60_000;
export const HOUR = 60 * MINUTE;

export function minuteOf(ts: number): number {
  return Math.floor(ts / MINUTE);
}
