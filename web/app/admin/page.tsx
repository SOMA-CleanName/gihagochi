// 랜딩 관리 — /admin (비밀번호 게이트). CTA·행동·사전신청 분석.
// 뷰: 개요(overview) / 세션(sessions) / 원본(raw). 미인증 → 로그인. noindex.

import type { Metadata } from "next";

import { AdminLogin } from "./_components/admin-login";
import { AdminLogout } from "./_components/admin-logout";
import { DateRange } from "./_components/date-range";
import { OverviewView } from "./_components/overview-view";
import { parseRawTab, RawView } from "./_components/raw-view";
import { SessionsView } from "./_components/sessions-view";
import { adminPassword, isAuthed } from "./_lib/auth";
import { buildOverview, buildSessions } from "./_lib/analytics";
import { filterData, resolveRange } from "./_lib/range";
import { fetchSheet, type SheetData } from "./_lib/sheet";

export const metadata: Metadata = {
  title: "앙코르 관리자",
  robots: { index: false, follow: false },
};

// 인증/시트 조회는 매 요청 실행 — 정적 프리렌더 금지.
export const dynamic = "force-dynamic";

type SearchParams = Promise<{
  view?: string;
  tab?: string;
  event?: string;
  range?: string;
  from?: string;
  to?: string;
}>;

const VIEWS = [
  { key: "overview", label: "개요" },
  { key: "sessions", label: "세션" },
  { key: "raw", label: "원본" },
] as const;
type View = (typeof VIEWS)[number]["key"];

function parseView(raw: string | undefined): View {
  return VIEWS.some((v) => v.key === raw) ? (raw as View) : "overview";
}

export default async function AdminPage(props: { searchParams: SearchParams }) {
  if (!adminPassword()) return <SetupNotice />;
  if (!(await isAuthed())) return <AdminLogin />;

  const sp = await props.searchParams;
  const view = parseView(sp.view);
  const range = resolveRange(sp);
  const result = await fetchSheet();

  return (
    <div className="mx-auto max-w-6xl px-6 py-10">
      <header className="flex flex-wrap items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold text-fg">랜딩 분석</h1>
          <p className="mt-1 text-sm text-fg-muted">
            CTA·행동·사전신청 데이터 (구글 시트 적재분).
          </p>
        </div>
        <AdminLogout />
      </header>

      <nav className="mt-6 flex gap-2 text-sm">
        {VIEWS.map((v) => (
          <a
            key={v.key}
            href={`/admin?view=${v.key}${range.query}`}
            className={`rounded-full px-4 py-1.5 transition ${
              v.key === view
                ? "bg-primary text-primary-on"
                : "border border-outline text-fg-muted hover:text-fg"
            }`}
          >
            {v.label}
          </a>
        ))}
      </nav>

      {result.state === "ok" && (
        <div className="mt-4 flex flex-wrap items-center justify-between gap-3">
          <DateRange
            view={view}
            activeKey={range.key}
            fromStr={range.fromStr}
            toStr={range.toStr}
          />
          <span className="text-xs text-fg-faint">표시 기간: {range.label}</span>
        </div>
      )}

      <div className="mt-6">
        {result.state === "unconfigured" && <ReadSetupNotice />}
        {result.state === "error" && (
          <div className="rounded-xl border border-error/40 bg-error/10 p-4 text-sm text-error">
            시트 조회 실패: {result.message}
          </div>
        )}
        {result.state === "ok" && (
          <ViewBody
            view={view}
            data={filterData(result.data, range)}
            tab={sp.tab}
            event={sp.event}
            q={range.query}
          />
        )}
      </div>
    </div>
  );
}

function ViewBody({
  view,
  data,
  tab,
  event,
  q,
}: {
  view: View;
  data: SheetData;
  tab?: string;
  event?: string;
  q: string;
}) {
  if (view === "raw") {
    return <RawView tab={parseRawTab(tab)} data={data} eventFilter={event} q={q} />;
  }
  const sessions = buildSessions(data);
  if (view === "sessions") return <SessionsView sessions={sessions} />;
  return <OverviewView ov={buildOverview(data, sessions)} />;
}

function SetupNotice() {
  return (
    <div className="mx-auto max-w-xl px-6 py-20 text-sm text-fg-muted">
      <h1 className="text-lg font-semibold text-fg">관리자 비활성화</h1>
      <p className="mt-2">
        <code className="rounded bg-surface-2 px-1">ADMIN_PASSWORD</code> 환경변수가 설정되지
        않았습니다. 배포 환경(Vercel)에 추가 후 다시 접속하세요.
      </p>
    </div>
  );
}

function ReadSetupNotice() {
  return (
    <div className="space-y-2 rounded-xl border border-warning/40 bg-warning/10 p-4 text-sm text-fg">
      <p className="font-semibold">시트 읽기 설정이 필요합니다.</p>
      <p className="text-fg-muted">
        Apps Script <code className="rounded bg-surface-2 px-1">doGet</code> + 환경변수{" "}
        <code className="rounded bg-surface-2 px-1">SHEETS_READ_TOKEN</code>
        (읽기 URL은 기존 <code className="rounded bg-surface-2 px-1">SHEETS_WEBHOOK_URL</code> 재사용)
        를 설정하세요.
      </p>
    </div>
  );
}
