import type { SheetData, SheetRow } from "./sheet";

// 날짜 구간 — KST 기준. 프리셋(오늘/7일/30일/전체) + 커스텀(from~to).
// ts는 ISO(UTC)로 적재되므로 KST 일자 경계로 환산해 비교한다.

const DAY = 86_400_000;
const KST = 9 * 60 * 60 * 1000;

export type RangeKey = "today" | "7d" | "30d" | "all";

export type ResolvedRange = {
  key: RangeKey | "custom";
  fromMs: number | null;
  toMs: number | null;
  fromStr: string;
  toStr: string;
  label: string;
  query: string; // 링크에 붙일 접미사 ('' | '&range=7d' | '&from=..&to=..')
};

function kstDateStr(ms: number): string {
  return new Date(ms + KST).toISOString().slice(0, 10);
}
function dayStartMs(dateStr: string): number {
  return Date.parse(`${dateStr}T00:00:00.000+09:00`);
}
function dayEndMs(dateStr: string): number {
  return Date.parse(`${dateStr}T23:59:59.999+09:00`);
}
function isDate(s: string | undefined): s is string {
  return !!s && /^\d{4}-\d{2}-\d{2}$/.test(s);
}

export function resolveRange(
  sp: { range?: string; from?: string; to?: string },
  nowMs?: number,
): ResolvedRange {
  const now = nowMs ?? Date.now();
  const today = kstDateStr(now);

  if (isDate(sp.from) || isDate(sp.to)) {
    const f = isDate(sp.from) ? sp.from : today;
    const t = isDate(sp.to) ? sp.to : today;
    const [a, b] = f <= t ? [f, t] : [t, f];
    return {
      key: "custom",
      fromMs: dayStartMs(a),
      toMs: dayEndMs(b),
      fromStr: a,
      toStr: b,
      label: `${a} ~ ${b}`,
      query: `&from=${a}&to=${b}`,
    };
  }

  const key: RangeKey =
    sp.range === "today" || sp.range === "7d" || sp.range === "30d" ? sp.range : "all";

  if (key === "all") {
    return {
      key,
      fromMs: null,
      toMs: null,
      fromStr: kstDateStr(now - 29 * DAY),
      toStr: today,
      label: "전체 기간",
      query: "",
    };
  }

  const days = key === "today" ? 1 : key === "7d" ? 7 : 30;
  const fromStr = kstDateStr(now - (days - 1) * DAY);
  return {
    key,
    fromMs: dayStartMs(fromStr),
    toMs: dayEndMs(today),
    fromStr,
    toStr: today,
    label: key === "today" ? "오늘" : `최근 ${days}일`,
    query: `&range=${key}`,
  };
}

export function filterData(data: SheetData, r: ResolvedRange): SheetData {
  if (r.fromMs == null && r.toMs == null) return data;
  const keep = (row: SheetRow): boolean => {
    const t = Date.parse(String(row.ts ?? ""));
    if (Number.isNaN(t)) return false;
    if (r.fromMs != null && t < r.fromMs) return false;
    if (r.toMs != null && t > r.toMs) return false;
    return true;
  };
  return {
    ...data,
    events: (data.events ?? []).filter(keep),
    signups: (data.signups ?? []).filter(keep),
  };
}
