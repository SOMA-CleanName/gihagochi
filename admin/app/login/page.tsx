// 관리자 로그인 (F-036).
// proxy.ts에서 미인증 시 여기로 redirect. 인증 성공 시 next 파라미터로 복귀.
import { LoginForm } from './login-form';

type SearchParams = Promise<{ next?: string; error?: string }>;

export default async function LoginPage(props: { searchParams: SearchParams }) {
  const { next, error } = await props.searchParams;

  return (
    <div className="flex min-h-screen items-center justify-center bg-neutral-50 p-4">
      <div className="w-full max-w-sm space-y-6 rounded-lg border bg-white p-8 shadow-sm">
        <header className="space-y-1 text-center">
          <h1 className="text-xl font-semibold">gihagochi 관리자</h1>
          <p className="text-sm text-neutral-600">관리자 계정으로 로그인</p>
        </header>

        {error === 'unauthorized' && (
          <div className="rounded border border-red-200 bg-red-50 p-3 text-sm text-red-700">
            관리자 권한이 없는 계정입니다.
          </div>
        )}

        <LoginForm redirectTo={next ?? '/'} />
      </div>
    </div>
  );
}
