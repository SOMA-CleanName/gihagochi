// 로그아웃 — Server Action 대신 form POST로 처리 (Server Component 헤더에서 form 사용).
import { NextResponse, type NextRequest } from 'next/server';

import { createClient } from '@/lib/supabase/server';

export async function POST(request: NextRequest) {
  const supabase = await createClient();
  await supabase.auth.signOut();
  return NextResponse.redirect(new URL('/login', request.url), { status: 303 });
}
