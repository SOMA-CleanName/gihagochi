// 서버 컴포넌트 / 서버 액션 / 라우트 핸들러에서 사용하는 Supabase 클라이언트.
// Next.js 16: cookies()는 async — 반드시 await.
import { createServerClient, type CookieOptions } from '@supabase/ssr';
import { cookies } from 'next/headers';

type CookieToSet = { name: string; value: string; options?: CookieOptions };

export async function createClient() {
  const cookieStore = await cookies();

  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll();
        },
        setAll(cookiesToSet: CookieToSet[]) {
          // Server Component에서 호출되면 Next.js가 set을 막음 — 무시.
          // proxy.ts가 세션 갱신을 책임지므로 여기서 실패해도 안전.
          try {
            cookiesToSet.forEach(({ name, value, options }) =>
              cookieStore.set(name, value, options),
            );
          } catch {
            // Server Component context — proxy가 처리
          }
        },
      },
    },
  );
}
