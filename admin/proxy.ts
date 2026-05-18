// Next.js 16에서 middleware.ts → proxy.ts로 이름 변경.
// 매 요청마다 Supabase 세션 갱신 + 관리자 인증 가드.
// edge runtime 미지원 — nodejs runtime으로만 실행됨.
import type { NextRequest } from 'next/server';

import { updateSession } from './lib/supabase/middleware';

export async function proxy(request: NextRequest) {
  return updateSession(request);
}

export const config = {
  matcher: [
    // 정적 자산 + Next 내부 + favicon 제외한 모든 경로
    '/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp|ico)).*)',
  ],
};
