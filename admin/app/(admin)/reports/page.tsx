// F-037 신고 처리 큐.
// Server Component — supabase로 직접 SELECT (admin RLS 정책 통과).
// 액션(dismissed/message_deleted/warned/suspended)은 _actions/ + _components/ (client).

import { createClient } from '@/lib/supabase/server';

import { ResolveActions } from './_components/ResolveActions';

const PAGE_SIZE = 20;
const TABS = ['pending', 'handled'] as const;
type Tab = (typeof TABS)[number];

const ACTION_LABEL: Record<string, string> = {
  dismissed: '무시',
  message_deleted: '메시지 삭제',
  warned: '경고',
  suspended: '정지',
};

type SearchParams = Promise<{ tab?: string; page?: string }>;

type ReportRow = {
  id: string;
  reporter_id: string;
  message_id: string;
  reason: string;
  status: Tab;
  resolution_action: string | null;
  resolution_note: string | null;
  handled_by: string | null;
  handled_at: string | null;
  created_at: string;
  reporter: { display_name: string } | null;
  message: {
    content: string | null;
    sender_id: string;
    sender: { display_name: string } | null;
  } | null;
};

function parseTab(raw: string | undefined): Tab {
  return (TABS as readonly string[]).includes(raw ?? '') ? (raw as Tab) : 'pending';
}

function parsePage(raw: string | undefined): number {
  const n = Number(raw ?? '1');
  return Number.isFinite(n) && n >= 1 ? Math.floor(n) : 1;
}

export default async function ReportsPage(props: { searchParams: SearchParams }) {
  const { tab: rawTab, page: rawPage } = await props.searchParams;
  const tab = parseTab(rawTab);
  const page = parsePage(rawPage);
  const from = (page - 1) * PAGE_SIZE;
  const to = from + PAGE_SIZE - 1;

  const supabase = await createClient();
  const { data, error } = await supabase
    .from('reports')
    .select(
      `id, reporter_id, message_id, reason, status,
       resolution_action, resolution_note, handled_by, handled_at, created_at,
       reporter:profiles!reports_reporter_id_fkey(display_name),
       message:messages!reports_message_id_fkey(content, sender_id,
         sender:profiles!messages_sender_id_fkey(display_name))`,
    )
    .eq('status', tab)
    .order('created_at', { ascending: tab === 'pending' })
    .range(from, to)
    .returns<ReportRow[]>();

  return (
    <div className="space-y-4">
      <header className="space-y-2">
        <h2 className="text-2xl font-semibold">신고 처리</h2>
        <p className="text-sm text-neutral-500">
          팬이 신고한 메시지를 검토하고 처리합니다. 처리는 되돌릴 수 없습니다.
        </p>
        <nav className="flex gap-2 text-sm">
          {TABS.map((t) => (
            <a
              key={t}
              href={`/reports?tab=${t}`}
              className={`rounded px-3 py-1 ${
                t === tab
                  ? 'bg-neutral-900 text-white'
                  : 'border bg-white text-neutral-700 hover:bg-neutral-100'
              }`}
            >
              {t === 'pending' ? '대기' : '처리 완료'}
            </a>
          ))}
        </nav>
      </header>

      {error && (
        <div className="rounded border border-red-200 bg-red-50 p-3 text-sm text-red-700">
          신고 조회 실패: {error.message}
        </div>
      )}

      {!error && (data ?? []).length === 0 && (
        <div className="rounded border bg-white p-6 text-sm text-neutral-500">
          {tab === 'pending' ? '대기 중인 신고가 없습니다.' : '처리된 신고가 없습니다.'}
        </div>
      )}

      {!error && (data ?? []).length > 0 && (
        <div className="overflow-hidden rounded-md border bg-white">
          <table className="w-full text-sm">
            <thead className="bg-neutral-50 text-left text-xs uppercase text-neutral-500">
              <tr>
                <th className="px-4 py-2">신고자</th>
                <th className="px-4 py-2">대상 (메시지 발신자)</th>
                <th className="px-4 py-2">메시지 내용</th>
                <th className="px-4 py-2">신고 사유</th>
                <th className="px-4 py-2">신고일</th>
                {tab === 'pending' && <th className="px-4 py-2">처리</th>}
                {tab === 'handled' && <th className="px-4 py-2">처리 결과</th>}
              </tr>
            </thead>
            <tbody>
              {(data ?? []).map((row) => (
                <tr key={row.id} className="border-t align-top">
                  <td className="px-4 py-3 text-neutral-700">
                    {row.reporter?.display_name ?? '-'}
                  </td>
                  <td className="px-4 py-3 text-neutral-700">
                    {row.message?.sender?.display_name ?? '-'}
                  </td>
                  <td className="px-4 py-3 text-neutral-600">
                    <span className="line-clamp-2">{row.message?.content ?? '(내용 없음)'}</span>
                  </td>
                  <td className="px-4 py-3 text-neutral-600">
                    <span className="line-clamp-2">{row.reason}</span>
                  </td>
                  <td className="px-4 py-3 text-neutral-600">
                    {formatDate(row.created_at)}
                  </td>
                  {tab === 'pending' && (
                    <td className="px-4 py-3">
                      <ResolveActions reportId={row.id} />
                    </td>
                  )}
                  {tab === 'handled' && (
                    <td className="px-4 py-3 text-neutral-700">
                      <div className="font-medium">
                        {ACTION_LABEL[row.resolution_action ?? ''] ?? row.resolution_action}
                      </div>
                      {row.resolution_note && (
                        <div className="mt-1 text-xs text-neutral-500">
                          {row.resolution_note}
                        </div>
                      )}
                    </td>
                  )}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      <footer className="flex items-center justify-between text-sm text-neutral-600">
        <span>페이지 {page}</span>
        <div className="flex gap-2">
          {page > 1 && (
            <a
              href={`/reports?tab=${tab}&page=${page - 1}`}
              className="rounded border bg-white px-3 py-1 hover:bg-neutral-100"
            >
              이전
            </a>
          )}
          {(data ?? []).length === PAGE_SIZE && (
            <a
              href={`/reports?tab=${tab}&page=${page + 1}`}
              className="rounded border bg-white px-3 py-1 hover:bg-neutral-100"
            >
              다음
            </a>
          )}
        </div>
      </footer>
    </div>
  );
}

function formatDate(iso: string): string {
  const d = new Date(iso);
  return `${d.getFullYear()}.${String(d.getMonth() + 1).padStart(2, '0')}.${String(d.getDate()).padStart(2, '0')}`;
}
