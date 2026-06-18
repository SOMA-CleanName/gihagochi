// 관리자 공통 레이아웃 — 사이드바 + 헤더. Server Component.
// 모든 (admin) 그룹 페이지는 이 레이아웃을 공유.
import Link from 'next/link';
import { redirect } from 'next/navigation';
import type { ReactNode } from 'react';

import { Providers } from '@/app/providers';
import { createClient } from '@/lib/supabase/server';

const NAV = [
  { href: '/', label: '대시보드' },
  { href: '/signups', label: '아이돌 가입 승인' },
  { href: '/reports', label: '신고 처리' },
  { href: '/users', label: '사용자 관리' },
  { href: '/idols', label: '아이돌 관리' },
  { href: '/landing', label: '랜딩 분석' },
];

export default async function AdminLayout({ children }: { children: ReactNode }) {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) redirect('/login');

  return (
    <Providers>
      <div className="flex min-h-screen">
        <aside className="w-60 shrink-0 border-r bg-neutral-50 p-4">
          <Link href="/" className="mb-6 block text-lg font-semibold">
            앙코르 관리자
          </Link>
          <nav className="flex flex-col gap-1">
            {NAV.map((item) => (
              <Link
                key={item.href}
                href={item.href}
                className="rounded px-3 py-2 text-sm hover:bg-neutral-200"
              >
                {item.label}
              </Link>
            ))}
          </nav>
        </aside>
        <div className="flex flex-1 flex-col">
          <header className="flex h-14 items-center justify-between border-b px-6">
            <h1 className="text-sm text-neutral-600">{user.email}</h1>
            <form action="/api/auth/signout" method="post">
              <button
                type="submit"
                className="text-sm text-neutral-600 hover:text-neutral-900"
              >
                로그아웃
              </button>
            </form>
          </header>
          <main className="flex-1 p-6">{children}</main>
        </div>
      </div>
    </Providers>
  );
}
