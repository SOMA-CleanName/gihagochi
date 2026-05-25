// proxy.ts에서 호출되는 Supabase 세션 갱신 + 관리자 role 체크.
// Next.js 16에서 middleware → proxy로 이름 변경. 본 파일은 헬퍼라 이름 유지.
import { createServerClient, type CookieOptions } from '@supabase/ssr';
import { NextResponse, type NextRequest } from 'next/server';

type CookieToSet = { name: string; value: string; options?: CookieOptions };

const PUBLIC_PATHS = ['/login', '/api/health'];

// 정적 자산 / Next 내부 / public 경로는 통과
function isPublicPath(pathname: string): boolean {
  if (PUBLIC_PATHS.includes(pathname)) return true;
  if (pathname.startsWith('/_next')) return true;
  if (pathname.startsWith('/api/')) return true;
  if (/\.(svg|png|jpg|jpeg|gif|webp|ico|css|js)$/i.test(pathname)) return true;
  return false;
}

export async function updateSession(request: NextRequest) {
  let response = NextResponse.next({ request });

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll();
        },
        setAll(cookiesToSet: CookieToSet[]) {
          cookiesToSet.forEach(({ name, value }) =>
            request.cookies.set(name, value),
          );
          response = NextResponse.next({ request });
          cookiesToSet.forEach(({ name, value, options }) =>
            response.cookies.set(name, value, options),
          );
        },
      },
    },
  );

  // 세션 갱신 (Supabase 권장 — 매 요청마다 호출 필수)
  const {
    data: { user },
  } = await supabase.auth.getUser();

  const pathname = request.nextUrl.pathname;

  if (isPublicPath(pathname)) {
    return response;
  }

  // 미로그인 → /login
  if (!user) {
    const url = request.nextUrl.clone();
    url.pathname = '/login';
    url.searchParams.set('next', pathname);
    return NextResponse.redirect(url);
  }

  // 관리자 role 게이트 — profiles 테이블이 진실의 원천 (JWT metadata 아님).
  // 정지된 관리자(status='suspended')는 동일하게 차단.
  const { data: profile, error: profileError } = await supabase
    .from('profiles')
    .select('role, status')
    .eq('id', user.id)
    .maybeSingle();

  if (profileError || !profile || profile.role !== 'admin' || profile.status !== 'active') {
    const url = request.nextUrl.clone();
    url.pathname = '/login';
    url.searchParams.set('error', 'unauthorized');
    return NextResponse.redirect(url);
  }

  return response;
}
