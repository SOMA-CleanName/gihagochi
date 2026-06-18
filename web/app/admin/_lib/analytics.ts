import type { SheetData, SheetRow } from "./sheet";

// 랜딩 행동 데이터 정제 — 원본 시트 행을 사람이 읽는 지표/세션으로 가공.

// ─── 한글 사전 ────────────────────────────────────────────────────────
export const EVENT_KR: Record<string, string> = {
  page_view: "페이지 방문",
  scroll_depth: "스크롤",
  section_view: "섹션 진입",
  cta_click: "CTA 클릭",
  character_click: "캐릭터 클릭",
  character_drag: "캐릭터 스와이프",
  email_focus: "이메일칸 포커스",
  role_select: "역할 선택",
  waitlist_submit_attempt: "사전신청 시도",
  waitlist_submit_error: "사전신청 오류",
  session_end: "이탈/종료",
  signup: "사전신청 완료",
};

export const SECTION_ORDER = [
  "top",
  "ways",
  "character",
  "journey",
  "how",
  "partners",
  "finale",
] as const;

export const SECTION_KR: Record<string, string> = {
  top: "히어로",
  ways: "함께하는 방식",
  character: "캐릭터",
  journey: "여정",
  how: "구조(1:N)",
  partners: "소속사",
  finale: "사전신청(피날레)",
};

export const CTA_KR: Record<string, string> = {
  hero_primary: "히어로 · 사전신청 하기",
  hero_secondary: "히어로 · 어떻게 작동하나요",
  header_cta: "헤더 · 사전신청",
  partner_email: "소속사 · 이메일",
  partner_instagram: "소속사 · 인스타그램",
  partner_x: "소속사 · X",
};

export function eventKr(e: string): string {
  return EVENT_KR[e] ?? e;
}
export function sectionKr(id: string): string {
  return SECTION_KR[id] ?? id;
}
export function ctaKr(label: string): string {
  return CTA_KR[label] ?? label;
}

// ─── props 파싱 ───────────────────────────────────────────────────────
function parseProps(row: SheetRow): Record<string, unknown> {
  const raw = row.props_json;
  if (typeof raw !== "string" || !raw) return {};
  try {
    return JSON.parse(raw) as Record<string, unknown>;
  } catch {
    return {};
  }
}

function str(v: unknown): string {
  return typeof v === "string" ? v : v == null ? "" : String(v);
}
function num(v: unknown): number {
  const n = typeof v === "number" ? v : Number(v);
  return Number.isFinite(n) ? n : 0;
}

function hostOf(url: string): string {
  if (!url) return "";
  try {
    return new URL(url).hostname.replace(/^www\./, "");
  } catch {
    return url.slice(0, 40);
  }
}

// ─── 사람이 읽는 한 줄 요약 (타임라인용) ──────────────────────────────
export function describe(event: string, label: string, props: Record<string, unknown>): string {
  switch (event) {
    case "page_view": {
      const src = str(props.utm_source) || "direct";
      const ref = hostOf(str(props.referrer));
      return ref && src === "direct" ? `유입: ${ref}` : `유입: ${src}`;
    }
    case "scroll_depth":
      return `${label}% 도달`;
    case "section_view":
      return sectionKr(label);
    case "cta_click":
      return ctaKr(label);
    case "character_click":
      return label;
    case "character_drag":
      return label === "next" ? "다음" : "이전";
    case "role_select":
      return `${label} 선택`;
    case "waitlist_submit_attempt":
      return `${label} 신청 시도`;
    case "waitlist_submit_error":
      return `${label} 신청 오류`;
    case "session_end": {
      const dur = Math.round(num(props.duration_ms) / 1000);
      const last = str(props.last_event);
      return `체류 ${dur}s · 마지막 ${eventKr(last) || "-"}`;
    }
    default:
      return label;
  }
}

// ─── 세션 ─────────────────────────────────────────────────────────────
export type TimelineItem = {
  ts: string;
  event: string;
  label: string;
  detail: string;
};

export type SessionSummary = {
  id: string;
  firstTs: string;
  lastTs: string;
  durationMs: number;
  eventCount: number;
  pageViews: number;
  source: string;
  referrer: string;
  sectionsReached: string[];
  maxScroll: number;
  ctaClicks: string[];
  roleSelected: string;
  submitAttempt: boolean;
  signedUp: boolean;
  signupRole: string;
  signupEmail: string;
  lastEvent: string;
  events: TimelineItem[];
};

// ─── 막대 항목 ────────────────────────────────────────────────────────
export type Bar = { key: string; label: string; count: number; pct: number };

export type Overview = {
  totalSessions: number;
  totalPageViews: number;
  totalEvents: number;
  signups: { total: number; idol: number; agency: number; fan: number };
  ctaTotal: number;
  ctaByLabel: Bar[];
  sectionFunnel: Bar[];
  scrollDist: Bar[];
  signupFunnel: Bar[];
  sources: Bar[];
  characterInteractions: number;
};

function pct(n: number, base: number): number {
  return base > 0 ? Math.round((n / base) * 100) : 0;
}

export function buildSessions(data: SheetData): SessionSummary[] {
  const events = data.events ?? [];
  const signups = data.signups ?? [];

  // 사전신청 — session_id로 매칭.
  const signupBySession = new Map<string, { role: string; email: string }>();
  for (const s of signups) {
    const sid = str(s.session_id);
    if (sid) signupBySession.set(sid, { role: str(s.role), email: str(s.email) });
  }

  const map = new Map<string, SessionSummary>();
  for (const row of events) {
    const sid = str(row.session_id);
    if (!sid) continue;
    const event = str(row.event);
    const label = str(row.label);
    const ts = str(row.ts);
    const props = parseProps(row);

    let s = map.get(sid);
    if (!s) {
      s = {
        id: sid,
        firstTs: ts,
        lastTs: ts,
        durationMs: 0,
        eventCount: 0,
        pageViews: 0,
        source: "",
        referrer: "",
        sectionsReached: [],
        maxScroll: 0,
        ctaClicks: [],
        roleSelected: "",
        submitAttempt: false,
        signedUp: false,
        signupRole: "",
        signupEmail: "",
        lastEvent: "",
        events: [],
      };
      map.set(sid, s);
    }

    s.eventCount += 1;
    if (ts && (!s.firstTs || ts < s.firstTs)) s.firstTs = ts;
    if (ts && ts > s.lastTs) s.lastTs = ts;
    s.events.push({ ts, event, label, detail: describe(event, label, props) });

    switch (event) {
      case "page_view":
        s.pageViews += 1;
        if (!s.source) s.source = str(props.utm_source) || "direct";
        if (!s.referrer) s.referrer = hostOf(str(props.referrer));
        break;
      case "section_view":
        if (label && !s.sectionsReached.includes(label)) s.sectionsReached.push(label);
        break;
      case "scroll_depth":
        s.maxScroll = Math.max(s.maxScroll, num(props.pct) || Number(label) || 0);
        break;
      case "cta_click":
        s.ctaClicks.push(label);
        break;
      case "role_select":
        s.roleSelected = label;
        break;
      case "waitlist_submit_attempt":
        s.submitAttempt = true;
        break;
      case "session_end":
        s.durationMs = Math.max(s.durationMs, num(props.duration_ms));
        break;
    }
  }

  for (const s of map.values()) {
    if (!s.source) s.source = "direct";
    if (!s.durationMs) {
      const d = new Date(s.lastTs).getTime() - new Date(s.firstTs).getTime();
      s.durationMs = Number.isFinite(d) && d > 0 ? d : 0;
    }
    s.events.sort((a, b) => a.ts.localeCompare(b.ts));
    s.lastEvent = s.events.length ? s.events[s.events.length - 1].event : "";
    s.sectionsReached.sort(
      (a, b) =>
        (SECTION_ORDER as readonly string[]).indexOf(a) -
        (SECTION_ORDER as readonly string[]).indexOf(b),
    );
    const su = signupBySession.get(s.id);
    if (su) {
      s.signedUp = true;
      s.signupRole = su.role;
      s.signupEmail = su.email;
    }
  }

  return [...map.values()].sort((a, b) => b.firstTs.localeCompare(a.firstTs));
}

export function buildOverview(data: SheetData, sessions: SessionSummary[]): Overview {
  const events = data.events ?? [];
  const signups = data.signups ?? [];
  const totalSessions = sessions.length;

  // 섹션 도달 — 도달 세션 수.
  const sectionFunnel: Bar[] = SECTION_ORDER.map((sec) => {
    const n = sessions.filter((s) => s.sectionsReached.includes(sec)).length;
    return { key: sec, label: sectionKr(sec), count: n, pct: pct(n, totalSessions) };
  });

  // 스크롤 깊이 — 해당 깊이 이상 도달 세션.
  const scrollDist: Bar[] = [25, 50, 75, 100].map((b) => {
    const n = sessions.filter((s) => s.maxScroll >= b).length;
    return { key: String(b), label: `${b}%`, count: n, pct: pct(n, totalSessions) };
  });

  // CTA — 클릭 횟수 기준.
  const ctaCount = new Map<string, number>();
  for (const e of events) {
    if (str(e.event) !== "cta_click") continue;
    const l = str(e.label);
    ctaCount.set(l, (ctaCount.get(l) ?? 0) + 1);
  }
  const ctaTotal = [...ctaCount.values()].reduce((a, b) => a + b, 0);
  const ctaByLabel: Bar[] = [...ctaCount.entries()]
    .map(([l, c]) => ({ key: l, label: ctaKr(l), count: c, pct: pct(c, ctaTotal) }))
    .sort((a, b) => b.count - a.count);

  // 사전신청 퍼널.
  const finaleSessions = sessions.filter((s) => s.sectionsReached.includes("finale")).length;
  const emailSessions = new Set(
    events.filter((e) => str(e.event) === "email_focus").map((e) => str(e.session_id)),
  ).size;
  const roleSessions = sessions.filter((s) => s.roleSelected).length;
  const attemptSessions = sessions.filter((s) => s.submitAttempt).length;
  const signedSessions = sessions.filter((s) => s.signedUp).length;
  const signupFunnel: Bar[] = [
    { key: "visit", label: "방문", count: totalSessions },
    { key: "finale", label: "피날레 도달", count: finaleSessions },
    { key: "email", label: "이메일칸 포커스", count: emailSessions },
    { key: "role", label: "역할 선택", count: roleSessions },
    { key: "attempt", label: "신청 시도", count: attemptSessions },
    { key: "signup", label: "신청 완료", count: signedSessions },
  ].map((x) => ({ ...x, pct: pct(x.count, totalSessions) }));

  // 유입 소스.
  const srcCount = new Map<string, number>();
  for (const s of sessions) srcCount.set(s.source, (srcCount.get(s.source) ?? 0) + 1);
  const sources: Bar[] = [...srcCount.entries()]
    .map(([k, c]) => ({ key: k, label: k, count: c, pct: pct(c, totalSessions) }))
    .sort((a, b) => b.count - a.count);

  // 사전신청 역할 분포.
  let idol = 0;
  let agency = 0;
  let fan = 0;
  for (const s of signups) {
    const r = str(s.role);
    if (r === "아이돌") idol += 1;
    else if (r === "소속사") agency += 1;
    else fan += 1;
  }

  const characterInteractions = events.filter(
    (e) => str(e.event) === "character_click" || str(e.event) === "character_drag",
  ).length;

  return {
    totalSessions,
    totalPageViews: events.filter((e) => str(e.event) === "page_view").length,
    totalEvents: events.length,
    signups: { total: signups.length, idol, agency, fan },
    ctaTotal,
    ctaByLabel,
    sectionFunnel,
    scrollDist,
    signupFunnel,
    sources,
    characterInteractions,
  };
}

// ─── 포맷 ─────────────────────────────────────────────────────────────
export function formatDuration(ms: number): string {
  const s = Math.round(ms / 1000);
  if (s < 60) return `${s}초`;
  const m = Math.floor(s / 60);
  const r = s % 60;
  return r ? `${m}분 ${r}초` : `${m}분`;
}

export function formatTime(iso: string): string {
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return iso;
  const p = (n: number) => String(n).padStart(2, "0");
  return `${p(d.getMonth() + 1)}.${p(d.getDate())} ${p(d.getHours())}:${p(d.getMinutes())}`;
}

export function formatTimeSec(iso: string): string {
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return iso;
  const p = (n: number) => String(n).padStart(2, "0");
  return `${p(d.getHours())}:${p(d.getMinutes())}:${p(d.getSeconds())}`;
}

export function shortId(id: string): string {
  return id.length > 10 ? `${id.slice(0, 8)}…` : id;
}
