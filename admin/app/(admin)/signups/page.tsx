// F-035 아이돌 가입 신청 큐.
// Server Component — supabase로 직접 SELECT (admin RLS 정책 통과).
// 액션(승인/반려)은 _actions/ + _components/ (client).

import { createClient } from '@/lib/supabase/server';

import { ActionButtons } from './_components/ActionButtons';

const PAGE_SIZE = 20;
const TABS = ['pending', 'approved', 'rejected', 'withdrawn'] as const;
type Tab = (typeof TABS)[number];

type SearchParams = Promise<{ tab?: string; page?: string }>;

type ApplicationRow = {
  id: string;
  user_id: string;
  stage_name: string;
  bio: string | null;
  application_note: string | null;
  status: Tab;
  rejection_reason: string | null;
  created_at: string;
  handled_at: string | null;
  profiles: { display_name: string } | null;
};

function parseTab(raw: string | undefined): Tab {
  return (TABS as readonly string[]).includes(raw ?? '') ? (raw as Tab) : 'pending';
}

function parsePage(raw: string | undefined): number {
  const n = Number(raw ?? '1');
  return Number.isFinite(n) && n >= 1 ? Math.floor(n) : 1;
}

export default async function SignupsPage(props: { searchParams: SearchParams }) {
  const { tab: rawTab, page: rawPage } = await props.searchParams;
  const tab = parseTab(rawTab);
  const page = parsePage(rawPage);
  const from = (page - 1) * PAGE_SIZE;
  const to = from + PAGE_SIZE - 1;

  const supabase = await createClient();
  const { data, error } = await supabase
    .from('idol_signup_applications')
    .select(
      'id, user_id, stage_name, bio, application_note, status, rejection_reason, created_at, handled_at, profiles!idol_signup_applications_user_id_fkey(display_name)',
    )
    .eq('status', tab)
    .order('created_at', { ascending: true })
    .range(from, to)
    .returns<ApplicationRow[]>();

  return (
    <div className="space-y-4">
      <header className="space-y-2">
        <h2 className="text-2xl font-semibold">아이돌 가입 신청</h2>
        <nav className="flex gap-2 text-sm">
          {TABS.map((t) => (
            <a
              key={t}
              href={`/signups?tab=${t}`}
              className={`rounded px-3 py-1 ${
                t === tab
                  ? 'bg-neutral-900 text-white'
                  : 'border bg-white text-neutral-700 hover:bg-neutral-100'
              }`}
            >
              {labelOf(t)}
            </a>
          ))}
        </nav>
      </header>

      {error && (
        <div className="rounded border border-red-200 bg-red-50 p-3 text-sm text-red-700">
          신청 조회 실패: {error.message}
        </div>
      )}

      {!error && (data ?? []).length === 0 && (
        <div className="rounded border bg-white p-6 text-sm text-neutral-500">
          처리할 신청이 없습니다.
        </div>
      )}

      {!error && (data ?? []).length > 0 && (
        <div className="overflow-hidden rounded-md border bg-white">
          <table className="w-full text-sm">
            <thead className="bg-neutral-50 text-left text-xs uppercase text-neutral-500">
              <tr>
                <th className="px-4 py-2">활동명</th>
                <th className="px-4 py-2">신청자</th>
                <th className="px-4 py-2">소개</th>
                <th className="px-4 py-2">신청일</th>
                {tab === 'rejected' && <th className="px-4 py-2">반려 사유</th>}
                {tab === 'pending' && <th className="px-4 py-2">액션</th>}
              </tr>
            </thead>
            <tbody>
              {(data ?? []).map((row) => (
                <tr key={row.id} className="border-t">
                  <td className="px-4 py-3 font-medium">{row.stage_name}</td>
                  <td className="px-4 py-3 text-neutral-700">
                    {row.profiles?.display_name ?? '-'}
                  </td>
                  <td className="px-4 py-3 text-neutral-600">
                    <span className="line-clamp-2">{row.bio ?? '-'}</span>
                  </td>
                  <td className="px-4 py-3 text-neutral-600">
                    {formatDate(row.created_at)}
                  </td>
                  {tab === 'rejected' && (
                    <td className="px-4 py-3 text-neutral-600">
                      {row.rejection_reason ?? '-'}
                    </td>
                  )}
                  {tab === 'pending' && (
                    <td className="px-4 py-3">
                      <ActionButtons applicationId={row.id} stageName={row.stage_name} />
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
              href={`/signups?tab=${tab}&page=${page - 1}`}
              className="rounded border bg-white px-3 py-1 hover:bg-neutral-100"
            >
              이전
            </a>
          )}
          {(data ?? []).length === PAGE_SIZE && (
            <a
              href={`/signups?tab=${tab}&page=${page + 1}`}
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

function labelOf(t: Tab): string {
  switch (t) {
    case 'pending':
      return '대기';
    case 'approved':
      return '승인';
    case 'rejected':
      return '반려';
    case 'withdrawn':
      return '철회';
  }
}

function formatDate(iso: string): string {
  const d = new Date(iso);
  return `${d.getFullYear()}.${String(d.getMonth() + 1).padStart(2, '0')}.${String(d.getDate()).padStart(2, '0')}`;
}
