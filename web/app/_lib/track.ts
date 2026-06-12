"use client";

/**
 * 랜딩 행동 분석 — 클라이언트 트래커.
 * track() → /api/track 로 전송 (서버가 SHEETS_WEBHOOK_URL=구글시트로 적재).
 * 자동 부착: session_id, elapsed_ms, path. 세션 종료(이탈) 추적 포함.
 */

export type TrackProps = Record<string, string | number | boolean | null>;

const DEBUG =
  typeof process !== "undefined" && process.env.NEXT_PUBLIC_TRACK_DEBUG === "1";

// ─── 세션 ─────────────────────────────────────────────────────────────
const SESSION_KEY = "encore_session";
let sessionId: string | null = null;
let sessionStartTs: number | null = null;
let pageLoadTs: number | null = null;
let lastEvent: string | null = null;
let lastEventTs: number | null = null;

function ensureSession(): string {
  if (sessionId) return sessionId;
  if (typeof window === "undefined") return "";
  try {
    const existing = window.sessionStorage.getItem(SESSION_KEY);
    if (existing) return (sessionId = existing);
  } catch {
    // sessionStorage 차단 환경
  }
  const fresh = `s${Date.now().toString(36)}${Math.random().toString(36).slice(2, 8)}`;
  sessionId = fresh;
  sessionStartTs = Date.now();
  try {
    window.sessionStorage.setItem(SESSION_KEY, fresh);
  } catch {
    // ignore
  }
  return fresh;
}

export function getSessionId(): string {
  return ensureSession();
}

export function markPageLoad(): void {
  if (pageLoadTs === null) pageLoadTs = Date.now();
  ensureSession();
  if (sessionStartTs === null) sessionStartTs = Date.now();
}

function elapsed(): number {
  return pageLoadTs === null ? 0 : Date.now() - pageLoadTs;
}

// ─── 중복 제거 (CTA 연타 방지) ─────────────────────────────────────────
const DEDUP: Record<string, number> = {
  cta_click: 1500,
  character_click: 800,
  character_drag: 1500,
  email_focus: 5000,
  section_view: 1000,
};
const dedupCache = new Map<string, number>();

function shouldEmit(event: string, props: TrackProps): boolean {
  const win = DEDUP[event];
  if (!win) return true;
  const key = `${event}::${props.label ?? props.id ?? ""}`;
  const now = Date.now();
  const prev = dedupCache.get(key);
  if (prev !== undefined && now - prev < win) return false;
  dedupCache.set(key, now);
  return true;
}

// ─── 송신 ─────────────────────────────────────────────────────────────
function post(event: string, props: TrackProps): void {
  if (typeof window === "undefined") return;
  try {
    void fetch("/api/track", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ event, props, ts: new Date().toISOString() }),
      keepalive: true,
    });
  } catch {
    // 분석 실패는 UX에 영향 없음
  }
}

export function track(event: string, props?: TrackProps): void {
  const base: TrackProps = props ? { ...props } : {};
  base.session_id = ensureSession();
  base.elapsed_ms = elapsed();
  if (typeof window !== "undefined") {
    base.path = window.location.pathname + window.location.search;
  }
  if (!shouldEmit(event, base)) return;
  post(event, base);
  lastEvent = event;
  lastEventTs = Date.now();
  if (DEBUG) console.log(`[track] ${event}`, base);
}

// ─── 세션 종료(이탈) ───────────────────────────────────────────────────
let lastSessionEndTs = 0;

function fireSessionEnd(reason: "pagehide" | "visibilitychange"): void {
  if (typeof window === "undefined") return;
  const now = Date.now();
  if (now - lastSessionEndTs < 1000) return;
  lastSessionEndTs = now;
  track("session_end", {
    reason,
    duration_ms: sessionStartTs ? Date.now() - sessionStartTs : 0,
    last_event: lastEvent ?? "",
    since_last_ms: lastEventTs ? Date.now() - lastEventTs : 0,
  });
}

/** layout/TrackPage mount 시 1회. cleanup 반환. */
export function installSessionEndListeners(): () => void {
  if (typeof window === "undefined") return () => {};
  const onHide = () => fireSessionEnd("pagehide");
  const onVis = () => {
    if (document.visibilityState === "hidden") fireSessionEnd("visibilitychange");
  };
  window.addEventListener("pagehide", onHide);
  document.addEventListener("visibilitychange", onVis);
  return () => {
    window.removeEventListener("pagehide", onHide);
    document.removeEventListener("visibilitychange", onVis);
  };
}
