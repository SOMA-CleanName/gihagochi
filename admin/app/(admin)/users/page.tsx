// F-038 사용자 관리.
// Server Component — supabase로 직접 SELECT (admin RLS). 액션은 _components/.
//
// searchParams:
//   - role: fan | idol | admin (없으면 전체)
//   - status: active | pending | suspended (없으면 전체)
//   - q: display_name 부분 일치 또는 uuid 정확 일치
//   - includeDeleted: 'true'면 deleted_at 있는 row도 포함 (기본: 제외)
//   - page: 1부터

import { createClient } from '@/lib/supabase/server';

import { UserRowActions } from './_components/UserRowActions';

const PAGE_SIZE = 20;
const ROLES = ['fan', 'idol', 'admin'] as const;
const STATUSES = ['active', 'pending', 'suspended'] as const;
type Role = (typeof ROLES)[number];
type Status = (typeof STATUSES)[number];

type SearchParams = Promise<{
  role?: string;
  status?: string;
  q?: string;
  includeDeleted?: string;
  page?: string;
}>;

type ProfileRow = {
  id: string;
  role: Role;
  status: Status;
  display_name: string;
  avatar_url: string | null;
  suspended_at: string | null;
  suspend_reason: string | null;
  created_at: string;
  deleted_at: string | null;
};

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function parseRole(raw: string | undefined): Role | null {
  return (ROLES as readonly string[]).includes(raw ?? '') ? (raw as Role) : null;
}
function parseStatus(raw: string | undefined): Status | null {
  return (STATUSES as readonly string[]).includes(raw ?? '') ? (raw as Status) : null;
}
function parsePage(raw: string | undefined): number {
  const n = Number(raw ?? '1');
  return Number.isFinite(n) && n >= 1 ? Math.floor(n) : 1;
}

export default async function UsersPage(props: { searchParams: SearchParams }) {
  const params = await props.searchParams;
  const role = parseRole(params.role);
  const status = parseStatus(params.status);
  const q = (params.q ?? '').trim();
  const includeDeleted = params.includeDeleted === 'true';
  const page = parsePage(params.page);
  const from = (page - 1) * PAGE_SIZE;
  const to = from + PAGE_SIZE - 1;

  const supabase = await createClient();
  let query = supabase
    .from('profiles')
    .select(
      'id, role, status, display_name, avatar_url, suspended_at, suspend_reason, created_at, deleted_at',
    )
    .order('created_at', { ascending: false })
    .range(from, to);

  if (role) query = query.eq('role', role);
  if (status) query = query.eq('status', status);
  if (!includeDeleted) query = query.is('deleted_at', null);
  if (q) {
    if (UUID_RE.test(q)) {
      query = query.eq('id', q);
    } else {
      query = query.ilike('display_name', `%${q}%`);
    }
  }

  const { data, error } = await query.returns<ProfileRow[]>();

  return (
    <div className="space-y-4">
      <header className="space-y-2">
        <h2 className="text-2xl font-semibold">사용자 관리</h2>
        <FilterForm role={role} status={status} q={q} includeDeleted={includeDeleted} />
      </header>

      {error && (
        <div className="rounded border border-red-200 bg-red-50 p-3 text-sm text-red-700">
          사용자 조회 실패: {error.message}
        </div>
      )}

      {!error && (data ?? []).length === 0 && (
        <div className="rounded border bg-white p-6 text-sm text-neutral-500">
          조건에 맞는 사용자가 없습니다.
        </div>
      )}

      {!error && (data ?? []).length > 0 && (
        <div className="overflow-hidden rounded-md border bg-white">
          <table className="w-full text-sm">
            <thead className="bg-neutral-50 text-left text-xs uppercase text-neutral-500">
              <tr>
                <th className="px-4 py-2">표시이름</th>
                <th className="px-4 py-2">role</th>
                <th className="px-4 py-2">status</th>
                <th className="px-4 py-2">가입일</th>
                <th className="px-4 py-2">정지 사유</th>
                <th className="px-4 py-2">액션</th>
              </tr>
            </thead>
            <tbody>
              {(data ?? []).map((row) => (
                <tr key={row.id} className="border-t">
                  <td className="px-4 py-3">
                    <div className="font-medium">{row.display_name}</div>
                    <div className="text-[11px] text-neutral-500">{row.id}</div>
                  </td>
                  <td className="px-4 py-3 text-neutral-700">{row.role}</td>
                  <td className="px-4 py-3">
                    <span
                      className={`rounded px-2 py-0.5 text-xs ${statusStyle(row.status)}`}
                    >
                      {row.status}
                    </span>
                    {row.deleted_at && (
                      <span className="ml-1 rounded bg-neutral-200 px-2 py-0.5 text-xs">
                        deleted
                      </span>
                    )}
                  </td>
                  <td className="px-4 py-3 text-neutral-600">
                    {formatDate(row.created_at)}
                  </td>
                  <td className="px-4 py-3 text-neutral-600">
                    {row.suspend_reason ?? '-'}
                  </td>
                  <td className="px-4 py-3">
                    <UserRowActions
                      userId={row.id}
                      displayName={row.display_name}
                      status={row.status}
                    />
                  </td>
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
              href={buildHref({ ...params, page: String(page - 1) })}
              className="rounded border bg-white px-3 py-1 hover:bg-neutral-100"
            >
              이전
            </a>
          )}
          {(data ?? []).length === PAGE_SIZE && (
            <a
              href={buildHref({ ...params, page: String(page + 1) })}
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

function FilterForm(props: {
  role: Role | null;
  status: Status | null;
  q: string;
  includeDeleted: boolean;
}) {
  return (
    <form
      method="get"
      action="/users"
      className="flex flex-wrap items-end gap-3 rounded border bg-white p-3"
    >
      <label className="text-xs">
        <span className="mb-1 block text-neutral-500">role</span>
        <select
          name="role"
          defaultValue={props.role ?? ''}
          className="rounded border px-2 py-1 text-sm"
        >
          <option value="">전체</option>
          {ROLES.map((r) => (
            <option key={r} value={r}>
              {r}
            </option>
          ))}
        </select>
      </label>
      <label className="text-xs">
        <span className="mb-1 block text-neutral-500">status</span>
        <select
          name="status"
          defaultValue={props.status ?? ''}
          className="rounded border px-2 py-1 text-sm"
        >
          <option value="">전체</option>
          {STATUSES.map((s) => (
            <option key={s} value={s}>
              {s}
            </option>
          ))}
        </select>
      </label>
      <label className="text-xs">
        <span className="mb-1 block text-neutral-500">검색 (이름 또는 UUID)</span>
        <input
          type="text"
          name="q"
          defaultValue={props.q}
          placeholder="display_name 부분일치"
          className="w-64 rounded border px-2 py-1 text-sm"
        />
      </label>
      <label className="flex items-center gap-1 text-xs">
        <input
          type="checkbox"
          name="includeDeleted"
          value="true"
          defaultChecked={props.includeDeleted}
        />
        탈퇴 포함
      </label>
      <button
        type="submit"
        className="rounded bg-neutral-900 px-3 py-1.5 text-xs text-white"
      >
        적용
      </button>
    </form>
  );
}

function buildHref(params: Record<string, string | undefined>): string {
  const usp = new URLSearchParams();
  for (const [k, v] of Object.entries(params)) {
    if (v) usp.set(k, v);
  }
  const q = usp.toString();
  return q ? `/users?${q}` : '/users';
}

function statusStyle(s: Status): string {
  switch (s) {
    case 'active':
      return 'bg-green-100 text-green-800';
    case 'suspended':
      return 'bg-red-100 text-red-800';
    case 'pending':
      return 'bg-yellow-100 text-yellow-800';
  }
}

function formatDate(iso: string): string {
  const d = new Date(iso);
  return `${d.getFullYear()}.${String(d.getMonth() + 1).padStart(2, '0')}.${String(d.getDate()).padStart(2, '0')}`;
}
