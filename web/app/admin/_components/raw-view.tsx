import type { SheetData, SheetRow } from "../_lib/sheet";

// 원본 — 시트 행 그대로. 이벤트/사전신청 탭 + 이벤트별 필터.

const RAW_TABS = ["events", "signups"] as const;
export type RawTab = (typeof RAW_TABS)[number];

const COLUMN_ORDER: Record<RawTab, string[]> = {
  events: ["ts", "event", "label", "path", "elapsed_ms", "session_id", "props_json"],
  signups: ["ts", "email", "role", "idol_name", "idol_sns", "company", "message", "path", "referrer", "session_id"],
};

export function parseRawTab(raw: string | undefined): RawTab {
  return (RAW_TABS as readonly string[]).includes(raw ?? "") ? (raw as RawTab) : "events";
}

export function RawView({
  tab,
  data,
  eventFilter,
  q = "",
}: {
  tab: RawTab;
  data: SheetData;
  eventFilter?: string;
  q?: string;
}) {
  const events = data.events ?? [];
  const signups = data.signups ?? [];

  const eventCounts = new Map<string, number>();
  for (const r of events) {
    const ev = String(r.event ?? "");
    eventCounts.set(ev, (eventCounts.get(ev) ?? 0) + 1);
  }

  const baseRows = tab === "events" ? events : signups;
  const rows =
    tab === "events" && eventFilter
      ? baseRows.filter((r) => String(r.event ?? "") === eventFilter)
      : baseRows;

  const sorted = [...rows].sort((a, b) =>
    String(b.ts ?? "").localeCompare(String(a.ts ?? "")),
  );
  const columns = buildColumns(tab, sorted);

  return (
    <div className="space-y-4">
      <nav className="flex gap-2 text-sm">
        {RAW_TABS.map((t) => (
          <a
            key={t}
            href={`/admin?view=raw&tab=${t}${q}`}
            className={`rounded-full px-4 py-1.5 transition ${
              t === tab
                ? "bg-primary text-primary-on"
                : "border border-outline text-fg-muted hover:text-fg"
            }`}
          >
            {t === "events" ? `이벤트 (${events.length})` : `사전신청 (${signups.length})`}
          </a>
        ))}
      </nav>

      {tab === "events" && eventCounts.size > 0 && (
        <div className="flex flex-wrap gap-2 text-xs">
          <a
            href={`/admin?view=raw&tab=events${q}`}
            className={`rounded-full px-3 py-1 transition ${
              !eventFilter
                ? "bg-fg text-bg"
                : "border border-outline-soft text-fg-muted hover:text-fg"
            }`}
          >
            전체 {events.length}
          </a>
          {[...eventCounts.entries()]
            .sort((a, b) => b[1] - a[1])
            .map(([ev, count]) => (
              <a
                key={ev}
                href={`/admin?view=raw&tab=events&event=${encodeURIComponent(ev)}${q}`}
                className={`rounded-full px-3 py-1 transition ${
                  eventFilter === ev
                    ? "bg-fg text-bg"
                    : "border border-outline-soft text-fg-muted hover:text-fg"
                }`}
              >
                {ev} {count}
              </a>
            ))}
        </div>
      )}

      {sorted.length === 0 ? (
        <div className="rounded-xl border border-outline-soft bg-surface-2/50 p-6 text-sm text-fg-muted">
          표시할 데이터가 없습니다.
        </div>
      ) : (
        <div className="overflow-x-auto rounded-xl border border-outline-soft">
          <table className="w-full text-sm">
            <thead className="bg-surface-2/60 text-left text-xs uppercase text-fg-faint">
              <tr>
                {columns.map((c) => (
                  <th key={c} className="whitespace-nowrap px-3 py-2 font-medium">
                    {c}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {sorted.map((row, i) => (
                <tr key={i} className="border-t border-outline-soft align-top">
                  {columns.map((c) => (
                    <td key={c} className="px-3 py-2 text-fg-muted">
                      <Cell column={c} value={row[c]} />
                    </td>
                  ))}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      <p className="text-xs text-fg-faint">최대 1000행 / 탭.</p>
    </div>
  );
}

function Cell({
  column,
  value,
}: {
  column: string;
  value: string | number | null | undefined;
}) {
  if (value === null || value === undefined || value === "") {
    return <span className="text-fg-faint">-</span>;
  }
  if (column === "ts") {
    return <span className="whitespace-nowrap">{formatTs(String(value))}</span>;
  }
  if (column === "props_json") {
    return (
      <details className="max-w-md">
        <summary className="cursor-pointer text-fg-faint">상세</summary>
        <pre className="mt-1 overflow-x-auto whitespace-pre-wrap break-all rounded bg-surface-2/60 p-2 text-[11px] text-fg-muted">
          {prettyJson(String(value))}
        </pre>
      </details>
    );
  }
  if (column === "session_id") {
    return <span className="font-mono text-xs text-fg-faint">{String(value)}</span>;
  }
  if (column === "idol_sns" || column === "referrer" || column === "path") {
    return <span className="break-all">{String(value)}</span>;
  }
  return <span>{String(value)}</span>;
}

function buildColumns(tab: RawTab, rows: SheetRow[]): string[] {
  const preferred = COLUMN_ORDER[tab];
  const present = new Set<string>();
  for (const r of rows) for (const k of Object.keys(r)) present.add(k);
  const ordered = preferred.filter((c) => present.has(c));
  const extras = [...present].filter((c) => !preferred.includes(c) && c !== "event");
  return tab === "events"
    ? ["event", ...ordered.filter((c) => c !== "event"), ...extras]
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
  const p = (n: number) => String(n).padStart(2, "0");
  return `${d.getFullYear()}.${p(d.getMonth() + 1)}.${p(d.getDate())} ${p(d.getHours())}:${p(d.getMinutes())}`;
}
