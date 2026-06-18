import {
  eventKr,
  formatDuration,
  formatTime,
  formatTimeSec,
  sectionKr,
  shortId,
  type SessionSummary,
} from "../_lib/analytics";

// 세션 — 최근 방문 세션 목록 + 펼치면 행동 타임라인. <details>로 클라이언트 JS 없이.

const LIMIT = 80;

export function SessionsView({ sessions }: { sessions: SessionSummary[] }) {
  const shown = sessions.slice(0, LIMIT);

  if (!sessions.length) {
    return (
      <p className="rounded-xl border border-outline-soft bg-surface-2/40 p-6 text-sm text-fg-muted">
        세션 데이터가 없습니다.
      </p>
    );
  }

  return (
    <div className="space-y-3">
      <p className="text-xs text-fg-faint">
        최근 {shown.length}개 세션 (최신순). 행을 클릭하면 행동 타임라인이 열립니다.
      </p>
      <div className="space-y-2">
        {shown.map((s) => (
          <SessionRow key={s.id} s={s} />
        ))}
      </div>
    </div>
  );
}

function SessionRow({ s }: { s: SessionSummary }) {
  return (
    <details className="group rounded-xl border border-outline-soft bg-surface-2/30 open:bg-surface-2/50">
      <summary className="flex cursor-pointer flex-wrap items-center gap-x-4 gap-y-1 px-4 py-3 text-sm">
        <span className="font-mono text-xs text-fg-faint">{shortId(s.id)}</span>
        <span className="text-fg-muted">{formatTime(s.firstTs)}</span>
        <span className="text-fg-muted">· {formatDuration(s.durationMs)}</span>
        <span className="text-fg-muted">· {s.eventCount}개 행동</span>
        <span className="text-fg-faint">· 유입 {s.source}</span>
        <span className="ml-auto flex flex-wrap items-center gap-1.5">
          {s.maxScroll > 0 && <Tag>{s.maxScroll}% 스크롤</Tag>}
          {s.ctaClicks.length > 0 && <Tag tone="primary">CTA {s.ctaClicks.length}</Tag>}
          {s.signedUp ? (
            <Tag tone="success">신청완료 {s.signupRole}</Tag>
          ) : s.submitAttempt ? (
            <Tag tone="warning">신청시도</Tag>
          ) : null}
        </span>
      </summary>

      <div className="space-y-4 border-t border-outline-soft px-4 py-4">
        <div className="grid gap-2 text-xs text-fg-muted sm:grid-cols-2">
          <Meta k="도달 섹션">
            {s.sectionsReached.length
              ? s.sectionsReached.map((x) => sectionKr(x)).join(" → ")
              : "-"}
          </Meta>
          <Meta k="CTA 클릭">
            {s.ctaClicks.length ? s.ctaClicks.join(", ") : "-"}
          </Meta>
          <Meta k="역할 선택">{s.roleSelected || "-"}</Meta>
          <Meta k="유입 경로">
            {s.referrer ? s.referrer : s.source}
            {s.signupEmail ? ` · ${s.signupEmail}` : ""}
          </Meta>
        </div>

        <ol className="space-y-1.5">
          {s.events.map((e, i) => (
            <li key={i} className="grid grid-cols-[4.5rem_7rem_1fr] items-baseline gap-2 text-xs">
              <span className="font-mono text-fg-faint">{formatTimeSec(e.ts)}</span>
              <span className="text-fg-muted">{eventKr(e.event)}</span>
              <span className="text-fg">{e.detail}</span>
            </li>
          ))}
        </ol>
      </div>
    </details>
  );
}

function Tag({
  children,
  tone = "neutral",
}: {
  children: React.ReactNode;
  tone?: "neutral" | "primary" | "success" | "warning";
}) {
  const cls =
    tone === "primary"
      ? "border-primary/40 text-primary"
      : tone === "success"
        ? "border-success/40 text-success"
        : tone === "warning"
          ? "border-warning/40 text-warning"
          : "border-outline text-fg-faint";
  return (
    <span className={`rounded-full border px-2 py-0.5 text-[11px] ${cls}`}>{children}</span>
  );
}

function Meta({ k, children }: { k: string; children: React.ReactNode }) {
  return (
    <p>
      <span className="text-fg-faint">{k}:</span> <span className="text-fg-muted">{children}</span>
    </p>
  );
}
