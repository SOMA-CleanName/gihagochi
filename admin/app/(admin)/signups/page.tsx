// F-XXX 관리자 페이지 템플릿.
// 복사 후 _template 폴더명을 실제 피처 path로 바꿔서 사용 (예: signups/, reports/).
//
// 패턴:
// 1. Server Component default — 데이터는 await로 직접 fetch
// 2. 인터랙션 (mutation/dialog) 필요한 부분만 별도 'use client' 컴포넌트로 분리
// 3. 정렬/필터는 searchParams로 표현 (Next.js 16: searchParams는 Promise)

import { createClient } from '@/lib/supabase/server';

type SearchParams = Promise<{ q?: string }>;

export default async function TemplatePage(props: { searchParams: SearchParams }) {
  const { q } = await props.searchParams;
  const supabase = await createClient();

  // 예시 — 실제 테이블/RLS는 피처 SPEC.md에 따름.
  // const { data, error } = await supabase.from('your_table').select('*').limit(50);

  return (
    <div className="space-y-4">
      <header className="flex items-center justify-between">
        <h2 className="text-2xl font-semibold">F-XXX 페이지 제목</h2>
        {/* <SearchInput initial={q} />  → client component */}
      </header>

      <div className="rounded-md border bg-white p-6 text-sm text-neutral-600">
        검색어: {q ?? '(없음)'} — supabase client 준비됨 ({typeof supabase === 'object' ? 'OK' : 'X'})
      </div>

      {/* 테이블 / 폼은 shadcn 컴포넌트로 구성 */}
    </div>
  );
}
