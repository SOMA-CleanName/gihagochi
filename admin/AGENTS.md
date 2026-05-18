# admin/AGENTS.md — Next.js stack 룰

루트 [`AGENTS.md`](../AGENTS.md)의 절대 룰은 그대로. 이 파일은 **관리자 웹 stack-specific**.

<!-- BEGIN:nextjs-agent-rules -->
> ⚠ **This is NOT the Next.js you know.**
> Next.js 16 has breaking changes — APIs, conventions, file structure may differ from training data.
> 작업 전에 `node_modules/next/dist/docs/01-app/02-guides/upgrading/version-16.md` 먼저 읽고, deprecation 경고는 무시하지 말 것.
<!-- END:nextjs-agent-rules -->

---

## Stack

- **Next.js 16.2+** (App Router, **Turbopack default**)
- **React 19.2** (Server Component default)
- **TypeScript 5+**
- **Tailwind v4** (`@tailwindcss/postcss`)
- **shadcn/ui** (CLI로 소스 복사)
- **`@supabase/ssr` + `@supabase/supabase-js`**
- **TanStack Query 5** (클라이언트 쿼리/뮤테이션 캐시)
- **react-hook-form + zod**
- **@sentry/nextjs 10+** (8.x는 Next 15까지만 지원)
- **recharts** (차트), **date-fns** (날짜)

## Run

```bash
npm install
npm run dev          # http://localhost:3000 (Turbopack)
npm run build        # production 빌드 (Turbopack)
npm run typecheck    # tsc --noEmit
npm run lint         # ESLint (next lint 제거됨 — flat config 사용)
```

---

## ★ Next.js 16 핵심 breaking change

| 변경 | 영향 |
|---|---|
| `middleware.ts` → **`proxy.ts`** | 함수명도 `middleware` → `proxy`. edge runtime 미지원. |
| `cookies()`, `headers()`, `draftMode()` | **반드시 `await`** (Next 15에서 도입, 16에서 동기 제거) |
| `params`, `searchParams` | Promise — `await props.params` |
| Turbopack default | `next dev`/`next build` 둘 다. webpack은 `--webpack` 명시 |
| `next lint` 제거 | ESLint CLI 직접 (`npm run lint` → `eslint`) |
| `images.domains` deprecated | `remotePatterns` 사용 |
| `revalidateTag(tag)` | `revalidateTag(tag, profile)` — 두 번째 인자 필수 |
| Sentry `onRequestError` | Sentry 10에서 `captureRequestError`로 이름 변경 → re-export로 처리 |
| AMP, `serverRuntimeConfig` | 완전 제거. 환경 변수로 대체 |
| Node 20.9+, TS 5.1+ | 최소 버전 상향 |

---

## 폴더 구조

```
admin/
├── proxy.ts                       # ★ Next 16: middleware → proxy 이름 변경
├── instrumentation.ts             # Sentry 서버 init
├── sentry.client.config.ts
├── sentry.server.config.ts
├── next.config.ts
├── tsconfig.json
├── lib/                           # 메인 빌더 영역 (인프라)
│   ├── supabase/
│   │   ├── server.ts              # Server Component / Route Handler 용
│   │   ├── client.ts              # Client Component 용
│   │   └── middleware.ts          # proxy.ts에서 호출하는 세션 갱신
│   ├── query-client.ts            # TanStack Query 싱글톤
│   └── utils.ts                   # cn() 등
└── app/
    ├── layout.tsx                 # 루트 레이아웃 (메인 빌더)
    ├── providers.tsx              # 클라이언트 provider 묶음
    ├── login/                     # 인증 외 영역
    │   ├── page.tsx
    │   └── login-form.tsx
    ├── api/                       # Route Handlers
    │   └── auth/signout/route.ts
    └── (admin)/                   # ★ 인증 필요 그룹
        ├── layout.tsx             # 사이드바 + 헤더 + Providers (메인 빌더)
        ├── page.tsx               # 대시보드
        ├── _template/             # ★ 새 페이지 복사 베이스 (라우팅 X)
        │   └── page.tsx
        └── <피처>/                # 작업 영역
            └── page.tsx
```

`(admin)` route group은 path에 영향 없음 — 인증 가드 + 공통 레이아웃 묶음.
`_template/`은 `_` 접두사라 라우팅에서 제외. 복사용.

---

## Server vs Client Component

**기본은 Server Component.** `'use client'`는 다음 경우에만:

- `useState`, `useEffect`, `useReducer` 등 hooks
- 이벤트 핸들러 (`onClick`, `onChange`)
- 브라우저 API (`window`, `localStorage`)
- `useRouter`, `usePathname` 등 client hooks

패턴:
- 페이지(`page.tsx`)는 Server Component default — 데이터 직접 fetch
- 인터랙티브한 부분만 별도 `*-form.tsx`, `*-button.tsx`로 분리 + `'use client'`

```tsx
// ✓ Server Component — async + await
export default async function Page(props: { searchParams: Promise<{ q?: string }> }) {
  const { q } = await props.searchParams;
  const supabase = await createClient();
  const { data } = await supabase.from('signups').select('*');
  return <SignupTable rows={data} />;
}

// ApproveButton만 'use client'
'use client';
export function ApproveButton({ id }: { id: string }) {
  return <button onClick={() => mutate(id)}>승인</button>;
}
```

---

## Supabase 클라이언트 분리

| 컨텍스트 | import |
|---|---|
| Server Component, Route Handler, Server Action | `@/lib/supabase/server` → `await createClient()` |
| Client Component (`'use client'`) | `@/lib/supabase/client` → `createClient()` (sync) |
| `proxy.ts` (세션 갱신) | `@/lib/supabase/middleware` → `updateSession(request)` |

**잘못된 import는 hydration 깨짐.** server.ts를 'use client'에서 부르면 cookies() 에러.

---

## proxy.ts (구 middleware.ts)

Next.js 16에서 이름 변경. 함수도 `export function proxy(...)`.

```ts
import { NextRequest } from 'next/server';
import { updateSession } from './lib/supabase/middleware';

export async function proxy(request: NextRequest) {
  return updateSession(request);
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|webp|ico)).*)'],
};
```

- 모든 요청마다 `supabase.auth.getUser()` 호출 → 세션 갱신 + 만료 방지
- 미인증 → `/login`으로 redirect
- 관리자 role 아니면 → `/login?error=unauthorized`

---

## 새 페이지 추가

```bash
cp -r "app/(admin)/_template" "app/(admin)/<폴더명>"
# 폴더명 == URL 경로 (예: signups → /signups)
```

순서: **SPEC.md → page.tsx (Server) → *-form/*-button (Client) → loading.tsx → error.tsx**

라우터 자동 등록 — 폴더 만들면 끝. Flutter/go_router처럼 routes.dart 합산 불필요.

---

## 폼

react-hook-form + zod 패턴 (login-form.tsx 참고):

```tsx
'use client';
const schema = z.object({ email: z.string().email(), ... });
const { register, handleSubmit, formState: { errors, isSubmitting } } =
  useForm<z.infer<typeof schema>>({ resolver: zodResolver(schema) });
```

뮤테이션 후 라우터 갱신:
```ts
router.replace(redirectTo);
router.refresh();  // RSC 캐시 무효화
```

---

## 데이터 변경 → UI 갱신

| 패턴 | 사용처 |
|---|---|
| `router.refresh()` | 단순 RSC 데이터 재요청 |
| `revalidateTag('users', 'max')` | 명시적 tag 무효화 (인자 2개 필수) |
| `updateTag('users')` | Server Action — read-your-writes |
| TanStack Query `invalidateQueries` | Client side 쿼리만 |

---

## 에러 / 로딩

각 라우트 segment에 `loading.tsx` / `error.tsx` 두면 자동 Suspense + Error Boundary.

```tsx
// app/(admin)/signups/loading.tsx
export default function Loading() {
  return <div className="animate-pulse">로딩 중…</div>;
}

// app/(admin)/signups/error.tsx
'use client';
export default function Error({ error, reset }: { error: Error; reset: () => void }) {
  return (
    <div>
      <p>{error.message}</p>
      <button onClick={reset}>다시 시도</button>
    </div>
  );
}
```

---

## shadcn/ui

```bash
npx shadcn@latest init       # 최초 1회 (Tailwind v4 호환 버전 확인 필요)
npx shadcn@latest add button input table dialog form card badge dropdown-menu
```

→ `components/ui/`에 소스 직접 복사. 수정 자유. 업그레이드는 다시 add.

---

## 환경 변수

| prefix | 노출 |
|---|---|
| `NEXT_PUBLIC_*` | 브라우저 번들에 포함 (Supabase URL, anon key, Sentry DSN) |
| (접두사 없음) | 서버 전용 (Sentry server DSN, 내부 API key) |

런타임 값 (빌드 시 lock 안 됨) 필요하면 `connection()` 호출 후 `process.env` 접근:

```tsx
import { connection } from 'next/server';
export default async function Page() {
  await connection();
  const val = process.env.RUNTIME_FLAG;
}
```

---

## 흔한 함정

- **`middleware.ts` 만들면 Next 16에서 deprecated 경고** → `proxy.ts`로
- **`cookies()` 동기 호출 → 런타임 에러** → `await cookies()`
- **`{ params }: { params: { id: string } }` → 타입 에러** → `params: Promise<{ id: string }>` + `await`
- **Server Component에서 `useState` → 빌드 에러** → `'use client'` 추가 또는 분리
- **Client Component에서 `cookies()` import → 번들 폭증/에러** → server.ts 사용
- **`revalidateTag('foo')` 인자 1개 → TS 에러** → `revalidateTag('foo', 'max')`
- **`images.domains` 사용 → deprecated 경고** → `remotePatterns`
- **`next lint` 실행 → 명령 없음** → `npm run lint` (eslint 직접)
- **`.next/dev` vs `.next` 디렉터리 혼동** → Next 16에서 `next dev`는 `.next/dev`로 출력 분리
- **Sentry `onRequestError` 직접 export → 못 찾음** → `captureRequestError`를 re-export

---

## 의존성 추가 필요 시

`package.json`은 메인 빌더 영역. 새 패키지 필요하면 **메인 빌더에게 핑** (사용 이유 + Next 16 호환성 확인).

이미 박혀있음: next, react, @supabase/ssr (인증/RLS), @tanstack/react-query (쿼리), react-hook-form + zod (폼), @sentry/nextjs 10+ (모니터링), recharts (차트), date-fns (날짜), lucide-react (아이콘), tailwind v4 + shadcn.

### Next 16 peer dependency 주의

- `@sentry/nextjs`는 **10.x 이상** (8.x는 Next 15까지만 지원)
- shadcn 추가 시 Tailwind v4 호환 버전 확인 (v3에서 v4로 PostCSS 플러그인 구조 변경됨)
- 새 codegen / babel 플러그인은 React Compiler 호환성 체크
