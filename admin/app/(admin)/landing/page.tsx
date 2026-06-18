// 랜딩 분석 — 구글 시트(Apps Script doGet)에 적재된 CTA/행동/사전신청 데이터 조회.
// 시트가 단일 진실원. Supabase 미경유 → Apps Script web app GET을 서버사이드 fetch.
// 필요한 env (admin): SHEETS_READ_URL, SHEETS_READ_TOKEN — 없으면 셋업 안내 표시.

import { connection } from 'next/server';

type SearchParams = Promise<{ tab?: string; event?: string }>;

type SheetRow = Record<string, string | number | null>;
type SheetData = { ok: boolean; events: SheetRow[]; signups: SheetRow[]; error?: string };

const TABS = ['events', 'signups'] as const;
type Tab = (typeof TABS)[number];

// 사람이 보기 좋은 컬럼 우선순위. 나머지 키는 뒤에 자동 append.
const COLUMN_ORDER: Record<Tab, string[]> = {
  events: ['ts', 'event', 'label', 'path', 'elapsed_ms', 'session_id', 'props_json'],
  signups: ['ts', 'email', 'role', 'idol_name', 'idol_sns', 'path', 'referrer', 'session_id'],
};

function parseTab(raw: string | undefined): Tab {
  return (TABS as readonly string[]).includes(raw ?? '') ? (raw as Tab) : 'events';
}

async function fetchSheet(): Promise<
  { state: 'unconfigured' } | { state: 'error'; message: string } | { state: 'ok'; data: SheetData }
> {
  await connection();
  const base = process.env.SHEETS_READ_URL;
  const token = process.env.SHEETS_READ_TOKEN;
  if (!base || !token) return { state: 'unconfigured' };

  const url = `${base}${base.includes('?') ? '&' : '?'}token=${encodeURIComponent(token)}&limit=1000`;
  try {
    const res = await fetch(url, { cache: 'no-store', redirect: 'follow' });
    if (!res.ok) return { state: 'error', message: `GET ${res.status}` };
    const data = (await res.json()) as SheetData;
    if (!data.ok) return { state: 'error', message: data.error ?? 'sheet returned ok:false' };
    return { state: 'ok', data };
  } catch (e) {
    return { state: 'error', message: e instanceof Error ? e.message : String(e) };
  }
}

export default async function LandingAnalyticsPage(props: { searchParams: SearchParams }) {
  const { tab: rawTab, event: eventFilter } = await props.searchParams;
  const tab = parseTab(rawTab);
  const result = await fetchSheet();

  return (
    <div className="space-y-4">
      <header className="space-y-2">
        <h2 className="text-2xl font-semibold">랜딩 분석</h2>
        <p className="text-sm text-neutral-500">
          랜딩페이지 CTA·행동·사전신청 데이터 (구글 시트 적재분).
        </p>
      </header>

      {result.state === 'unconfigured' && <SetupNotice />}

      {result.state === 'error' && (
        <div className="rounded border border-red-200 bg-red-50 p-3 text-sm text-red-700">
          시트 조회 실패: {result.message}
        </div>
      )}

      {result.state === 'ok' && (
        <SheetView tab={tab} data={result.data} eventFilter={eventFilter} />
      )}
    </div>
  );
}

function SheetView({
  tab,
  data,
  eventFilter,
}: {
  tab: Tab;
  data: SheetData;
  eventFilter?: string;
}) {
  const events = data.events ?? [];
  const signups = data.signups ?? [];

  // 이벤트 종류별 카운트 (필터 칩).
  const eventCounts = new Map<string, number>();
  for (const r of events) {
    const ev = String(r.event ?? '');
    eventCounts.set(ev, (eventCounts.get(ev) ?? 0) + 1);
  }

  const baseRows = tab === 'events' ? events : signups;
  const rows =
    tab === 'events' && eventFilter
      ? baseRows.filter((r) => String(r.event ?? '') === eventFilter)
      : baseRows;

  // 최신순 — ts 내림차순.
  const sorted = [...rows].sort((a, b) =>
    String(b.ts ?? '').localeCompare(String(a.ts ?? '')),
  );

  const columns = buildColumns(tab, sorted);

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-center gap-4">
        <nav className="flex gap-2 text-sm">
          {TABS.map((t) => (
            <a
              key={t}
              href={`/landing?tab=${t}`}
              className={`rounded px-3 py-1 ${
                t === tab
                  ? 'bg-neutral-900 text-white'
                  : 'border bg-white text-neutral-700 hover:bg-neutral-100'
              }`}
            >
              {t === 'events' ? `이벤트 (${events.length})` : `사전신청 (${signups.length})`}
            </a>
          ))}
        </nav>
      </div>

      {tab === 'events' && eventCounts.size > 0 && (
        <div className="flex flex-wrap gap-2 text-xs">
          <a
            href="/landing?tab=events"
            className={`rounded-full px-3 py-1 ${
              !eventFilter
                ? 'bg-neutral-900 text-white'
                : 'border bg-white text-neutral-700 hover:bg-neutral-100'
            }`}
          >
            전체 {events.length}
          </a>
          {[...eventCounts.entries()]
            .sort((a, b) => b[1] - a[1])
            .map(([ev, count]) => (
              <a
                key={ev}
                href={`/landing?tab=events&event=${encodeURIComponent(ev)}`}
                className={`rounded-full px-3 py-1 ${
                  eventFilter === ev
                    ? 'bg-neutral-900 text-white'
                    : 'border bg-white text-neutral-700 hover:bg-neutral-100'
                }`}
              >
                {ev} {count}
              </a>
            ))}
        </div>
      )}

      {sorted.length === 0 ? (
        <div className="rounded border bg-white p-6 text-sm text-neutral-500">
          표시할 데이터가 없습니다.
        </div>
      ) : (
        <div className="overflow-x-auto rounded-md border bg-white">
          <table className="w-full text-sm">
            <thead className="bg-neutral-50 text-left text-xs uppercase text-neutral-500">
              <tr>
                {columns.map((c) => (
                  <th key={c} className="whitespace-nowrap px-3 py-2">
                    {c}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {sorted.map((row, i) => (
                <tr key={i} className="border-t align-top">
                  {columns.map((c) => (
                    <td key={c} className="px-3 py-2 text-neutral-700">
                      <Cell column={c} value={row[c]} />
                    </td>
                  ))}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      <p className="text-xs text-neutral-400">
        최대 1000행 / 탭. 더 필요하면 시트에서 직접 확인하세요.
      </p>
    </div>
  );
}

function Cell({ column, value }: { column: string; value: string | number | null | undefined }) {
  if (value === null || value === undefined || value === '') {
    return <span className="text-neutral-300">-</span>;
  }
  if (column === 'ts') {
    return <span className="whitespace-nowrap text-neutral-600">{formatTs(String(value))}</span>;
  }
  if (column === 'props_json') {
    const text = String(value);
    return (
      <details className="max-w-md">
        <summary className="cursor-pointer text-neutral-500">상세</summary>
        <pre className="mt-1 overflow-x-auto whitespace-pre-wrap break-all rounded bg-neutral-50 p-2 text-[11px] text-neutral-600">
          {prettyJson(text)}
        </pre>
      </details>
    );
  }
  if (column === 'session_id') {
    return <span className="font-mono text-xs text-neutral-500">{String(value)}</span>;
  }
  if (column === 'idol_sns' || column === 'referrer' || column === 'path') {
    return <span className="break-all text-neutral-600">{String(value)}</span>;
  }
  return <span>{String(value)}</span>;
}

function buildColumns(tab: Tab, rows: SheetRow[]): string[] {
  const preferred = COLUMN_ORDER[tab];
  const present = new Set<string>();
  for (const r of rows) for (const k of Object.keys(r)) present.add(k);
  // event 컬럼은 events 탭에서 칩으로 대체되지만, 필터 안 걸었을 땐 보이는 게 유용.
  const ordered = preferred.filter((c) => present.has(c));
  const extras = [...present].filter((c) => !preferred.includes(c) && c !== 'event');
  return tab === 'events' ? ['event', ...ordered.filter((c) => c !== 'event'), ...extras]
    : [...ordered, ...extras];
}

function prettyJson(text: string): string {
  try {
    return JSON.stringify(JSON.parse(text), null, 2);
  } catch {
    return text;
  }
}

function formatTs(iso: string): string {
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return iso;
  const p = (n: number) => String(n).padStart(2, '0');
  return `${d.getFullYear()}.${p(d.getMonth() + 1)}.${p(d.getDate())} ${p(d.getHours())}:${p(d.getMinutes())}`;
}

function SetupNotice() {
  return (
    <div className="space-y-3 rounded-md border border-amber-200 bg-amber-50 p-4 text-sm text-amber-900">
      <p className="font-semibold">시트 읽기 설정이 필요합니다.</p>
      <p className="text-amber-800">
        Apps Script에 <code className="rounded bg-amber-100 px-1">doGet</code>을 추가하고, admin 환경변수
        2개를 설정하세요. (자세한 방법: 이 폴더의 <code className="rounded bg-amber-100 px-1">APPSCRIPT.md</code>)
      </p>
      <ul className="ml-4 list-disc space-y-1 text-amber-800">
        <li>
          <code className="rounded bg-amber-100 px-1">SHEETS_READ_URL</code> — Apps Script 웹앱 배포 URL
        </li>
        <li>
          <code className="rounded bg-amber-100 px-1">SHEETS_READ_TOKEN</code> — doGet과 맞출 비밀
          토큰
        </li>
      </ul>
    </div>
  );
}
