import Link from "next/link";

export default function Home() {
  return (
    <>
      <SiteHeader />
      <main>
        <Hero />
        <Ways />
        <Character />
        <Journey />
        <HowItWorks />
      </main>
      <SiteFooter />
    </>
  );
}

function SiteHeader() {
  return (
    <header className="sticky top-0 z-50 w-full border-b border-border bg-background">
      <div className="mx-auto flex h-14 max-w-6xl items-center justify-between px-6">
        <Link href="/" className="text-base font-semibold tracking-tight">
          앙코르
        </Link>
        <nav className="hidden items-center gap-7 text-sm text-foreground-muted md:flex">
          <a href="#ways" className="transition hover:text-foreground">
            함께하는 방식
          </a>
          <a href="#character" className="transition hover:text-foreground">
            캐릭터
          </a>
          <a href="#journey" className="transition hover:text-foreground">
            여정
          </a>
          <a href="#how" className="transition hover:text-foreground">
            구조
          </a>
        </nav>
        <a
          href="mailto:hello@encore.app?subject=아이돌%20활동%20문의"
          className="rounded-full border border-border px-3.5 py-1.5 text-sm font-medium transition hover:border-foreground-muted"
        >
          아이돌로 활동하기
        </a>
      </div>
    </header>
  );
}

function Hero() {
  return (
    <section className="relative overflow-hidden">
      {/* 옅은 보라 라디얼 글로우 */}
      <div
        aria-hidden
        className="pointer-events-none absolute left-1/2 top-0 -z-10 h-[600px] w-[1200px] -translate-x-1/2 rounded-full opacity-60 blur-3xl"
        style={{
          background:
            "radial-gradient(closest-side, rgba(103,80,164,0.12), transparent)",
        }}
      />

      <div className="mx-auto max-w-6xl px-6 pt-24 pb-28 sm:pt-32 sm:pb-36">
        <div className="mx-auto max-w-3xl text-center">
          <div className="mb-7 inline-flex items-center gap-2 rounded-full border border-border bg-surface px-3 py-1 text-xs font-medium text-foreground-muted">
            <span className="h-1.5 w-1.5 rounded-full bg-brand" />
            함께 자라는 아이돌의 모든 순간
          </div>

          <h1 className="text-balance text-4xl font-semibold leading-[1.1] tracking-tight text-foreground sm:text-6xl">
            당신의 아이돌,
            <br className="hidden sm:inline" /> 함께 자라요.
          </h1>

          <p className="mt-6 text-pretty text-lg leading-relaxed text-foreground-muted sm:text-xl">
            지켜보고 · 대화하고 · 후원하며.
            <br />
            작은 응원이 한 명의 아이돌을 무대로 데려갑니다.
          </p>

          <div className="mt-10 flex flex-col items-center justify-center gap-3 sm:flex-row">
            <a
              href="#notify"
              className="inline-flex h-11 items-center justify-center rounded-full bg-brand px-6 text-sm font-semibold text-brand-foreground transition hover:opacity-90"
            >
              출시 알림 받기
            </a>
            <a
              href="mailto:hello@encore.app?subject=아이돌%20활동%20문의"
              className="inline-flex h-11 items-center justify-center rounded-full px-5 text-sm font-medium text-foreground-muted transition hover:text-foreground"
            >
              아이돌로 활동하기 →
            </a>
          </div>

          {/* 4가지 함께하는 방식 — Hero 하단 인디케이터 (다음 섹션에서 자세히) */}
          <ul className="mt-20 grid grid-cols-2 gap-x-8 gap-y-5 text-sm sm:flex sm:justify-center sm:gap-x-12">
            {[
              { k: "지켜보기", i: "01" },
              { k: "대화하기", i: "02" },
              { k: "후원하기", i: "03" },
              { k: "성장시키기", i: "04" },
            ].map((it) => (
              <li key={it.k} className="inline-flex items-center gap-2">
                <span className="font-mono text-[11px] tracking-wider text-foreground-faint">
                  {it.i}
                </span>
                <span className="font-medium text-foreground">{it.k}</span>
              </li>
            ))}
          </ul>
        </div>
      </div>
    </section>
  );
}

const WAYS = [
  {
    index: "01",
    title: "지켜보기",
    body: "매일의 채팅과 일상이 천천히 쌓입니다. 한 명의 아이돌이 자라는 모든 순간을, 처음부터 함께 봅니다.",
  },
  {
    index: "02",
    title: "대화하기",
    body: "팬의 메시지는 그 아이돌에게만. 아이돌의 한 마디는 응원하는 모두에게. 가장 가까운 거리에서 매일 안부를 묻습니다.",
  },
  {
    index: "03",
    title: "후원하기",
    badge: "준비 중",
    body: "작은 응원이 모여 무대가 됩니다. 출시 이후 단계적으로 열리는 후원으로, 아이돌의 다음 길에 손을 보탭니다.",
  },
  {
    index: "04",
    title: "성장시키기",
    body: "당신과 함께한 시간이 아이돌의 다음 챕터가 됩니다. 첫 무대, 첫 콘서트, 그 너머의 여정까지.",
  },
] satisfies ReadonlyArray<{
  index: string;
  title: string;
  body: string;
  badge?: string;
}>;

function Ways() {
  return (
    <section id="ways" className="border-t border-border bg-surface">
      <div className="mx-auto max-w-6xl px-6 py-24 sm:py-32">
        <div className="mx-auto max-w-2xl text-center">
          <p className="text-xs font-semibold uppercase tracking-[0.2em] text-brand">
            함께하는 방식
          </p>
          <h2 className="mt-4 text-balance text-3xl font-semibold leading-tight tracking-tight text-foreground sm:text-4xl">
            네 가지 방식으로,
            <br className="hidden sm:inline" /> 한 명의 아이돌과.
          </h2>
          <p className="mt-5 text-pretty text-base leading-relaxed text-foreground-muted sm:text-lg">
            앙코르는 매일의 작은 순간이 한 명의 아이돌을 무대로 데려가는
            자리입니다.
          </p>
        </div>

        <div className="mt-16 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
          {WAYS.map((w) => (
            <article
              key={w.index}
              className="group flex flex-col gap-5 rounded-2xl border border-border bg-background p-6 transition hover:border-border-strong hover:shadow-[0_20px_40px_-30px_rgba(103,80,164,0.25)]"
            >
              <header className="flex items-center justify-between">
                <span className="font-mono text-[11px] tracking-wider text-foreground-faint">
                  {w.index}
                </span>
                {w.badge ? (
                  <span className="rounded-full bg-brand-soft px-2 py-0.5 text-[10px] font-semibold tracking-wider text-brand">
                    {w.badge}
                  </span>
                ) : null}
              </header>
              <h3 className="text-xl font-semibold tracking-tight text-foreground">
                {w.title}
              </h3>
              <p className="text-sm leading-relaxed text-foreground-muted">
                {w.body}
              </p>
            </article>
          ))}
        </div>
      </div>
    </section>
  );
}

const CHARACTER_FEATURES = [
  {
    title: "표정으로 답해요",
    body: "아이돌이 보낸 메시지의 톤에 맞춰 캐릭터의 표정과 동작이 함께 움직입니다.",
  },
  {
    title: "당신의 화면에서만",
    body: "팬 한 명 한 명의 시점에서, 아이돌의 분신이 정면을 바라보고 말합니다.",
  },
  {
    title: "함께 자라요",
    body: "후원과 함께한 시간이 쌓이면 의상·공간·표현이 단계적으로 풍부해집니다.",
  },
] as const;

function Character() {
  return (
    <section id="character" className="border-t border-border">
      <div className="mx-auto max-w-6xl px-6 py-24 sm:py-32">
        <div className="grid items-center gap-12 lg:grid-cols-2 lg:gap-20">
          {/* 좌: 카피 */}
          <div>
            <p className="text-xs font-semibold uppercase tracking-[0.2em] text-brand">
              곧 만나요
            </p>
            <h2 className="mt-4 text-balance text-3xl font-semibold leading-tight tracking-tight text-foreground sm:text-4xl">
              채팅에 맞춰 움직이는,
              <br className="hidden sm:inline" />
              아이돌의 분신.
            </h2>
            <p className="mt-5 text-pretty text-base leading-relaxed text-foreground-muted sm:text-lg">
              곧 도입될 2.5D 맞춤 캐릭터로, 당신의 아이돌이 화면 너머에서 살아
              움직입니다. 메시지 한 줄, 작은 후원, 그리고 함께한 시간이
              캐릭터에 그대로 쌓여요.
            </p>

            <ul className="mt-10 space-y-5">
              {CHARACTER_FEATURES.map((f) => (
                <li key={f.title} className="flex gap-4">
                  <span
                    aria-hidden
                    className="mt-2.5 h-1.5 w-1.5 shrink-0 rounded-full bg-brand"
                  />
                  <div>
                    <p className="font-semibold text-foreground">{f.title}</p>
                    <p className="mt-1 text-sm leading-relaxed text-foreground-muted">
                      {f.body}
                    </p>
                  </div>
                </li>
              ))}
            </ul>

            <p className="mt-10 text-xs text-foreground-subtle">
              * 1차 출시 이후 단계적으로 도입됩니다.
            </p>
          </div>

          {/* 우: 추상 시각화 */}
          <div className="relative">
            <CharacterPreview />
          </div>
        </div>
      </div>
    </section>
  );
}

function CharacterPreview() {
  return (
    <div
      className="relative aspect-[4/5] w-full overflow-hidden rounded-3xl border border-border"
      style={{
        background:
          "linear-gradient(135deg, #F5F0FB 0%, #FFFFFF 55%, #FFFFFF 100%)",
      }}
    >
      {/* 보라 블러 글로우 */}
      <div
        aria-hidden
        className="absolute left-1/2 top-1/2 h-[420px] w-[420px] -translate-x-1/2 -translate-y-1/2 rounded-full opacity-60 blur-3xl"
        style={{
          background:
            "radial-gradient(circle, rgba(103,80,164,0.30), transparent 60%)",
        }}
      />

      {/* 캐릭터 추상 실루엣 */}
      <div className="absolute left-1/2 top-[58%] -translate-x-1/2 -translate-y-1/2">
        <svg
          viewBox="0 0 200 240"
          className="h-56 w-44 sm:h-72 sm:w-56"
          aria-hidden
        >
          <defs>
            <linearGradient id="charGrad" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0" stopColor="#8B6FC8" />
              <stop offset="1" stopColor="#6750A4" />
            </linearGradient>
          </defs>
          {/* 어깨 */}
          <ellipse
            cx="100"
            cy="230"
            rx="95"
            ry="35"
            fill="url(#charGrad)"
            opacity="0.85"
          />
          {/* 목 */}
          <rect
            x="85"
            y="140"
            width="30"
            height="55"
            fill="url(#charGrad)"
            opacity="0.85"
          />
          {/* 머리 */}
          <circle cx="100" cy="95" r="52" fill="url(#charGrad)" />
          {/* 머리 위 작은 하이라이트 */}
          <ellipse
            cx="85"
            cy="75"
            rx="14"
            ry="8"
            fill="#FFFFFF"
            opacity="0.18"
          />
        </svg>
      </div>

      {/* 떠다니는 채팅 버블 (좌상) */}
      <div className="absolute left-5 top-6 max-w-[200px] rounded-2xl rounded-bl-md border border-border bg-background px-3.5 py-2.5 shadow-[0_10px_30px_-10px_rgba(103,80,164,0.25)]">
        <p className="text-xs font-medium text-foreground">
          오늘 콘서트 너무 좋았어 ✨
        </p>
        <p className="mt-1 text-[10px] text-foreground-faint">
          아이돌의 한 마디
        </p>
      </div>

      {/* 떠다니는 액션 라벨 (우중) */}
      <div className="absolute right-5 top-[40%] flex flex-col items-end gap-2">
        <span className="rounded-full border border-border bg-background/90 px-3 py-1 text-[11px] font-medium text-foreground-muted backdrop-blur">
          → 미소
        </span>
        <span className="rounded-full border border-border bg-background/90 px-3 py-1 text-[11px] font-medium text-foreground-muted backdrop-blur">
          → 손 흔들기
        </span>
      </div>

      {/* preview 라벨 (좌하) */}
      <div className="absolute bottom-5 left-5">
        <span className="rounded-full bg-brand px-2.5 py-1 text-[10px] font-semibold tracking-[0.15em] text-brand-foreground">
          v0.1 PREVIEW
        </span>
      </div>

      {/* 진행 인디케이터 (우하) */}
      <div className="absolute bottom-5 right-5 text-right">
        <p className="text-[10px] font-medium uppercase tracking-wider text-foreground-faint">
          Coming
        </p>
        <p className="font-mono text-xs font-semibold text-foreground">
          2026 →
        </p>
      </div>
    </div>
  );
}

const JOURNEY = [
  {
    title: "디지털에서 만나",
    body: "매일의 채팅으로 가까워져요. 응원하는 시간이 그 아이돌과 당신만의 기록으로 쌓입니다.",
  },
  {
    title: "함께 자라요",
    body: "후원과 응원이 아이돌의 다음 길에 손을 보탭니다. 변화를 가장 가까이서 지켜봐요.",
  },
  {
    title: "무대에서 마주봐요",
    body: "디지털에서 쌓은 시간이 첫 무대, 첫 콘서트, 그리고 직접 만나는 자리로 이어집니다.",
  },
] as const;

function Journey() {
  return (
    <section id="journey" className="border-t border-border bg-surface">
      <div className="mx-auto max-w-6xl px-6 py-24 sm:py-32">
        <div className="mx-auto max-w-2xl text-center">
          <p className="text-xs font-semibold uppercase tracking-[0.2em] text-brand">
            함께 가는 길
          </p>
          <h2 className="mt-4 text-balance text-3xl font-semibold leading-tight tracking-tight text-foreground sm:text-4xl">
            디지털에서 만나,
            <br className="hidden sm:inline" />
            무대에서 마주봐요.
          </h2>
          <p className="mt-5 text-pretty text-base leading-relaxed text-foreground-muted sm:text-lg">
            매일의 작은 대화로 시작해, 첫 무대와 그 너머까지. 앙코르는
            디지털과 오프라인을 잇는 자리입니다.
          </p>
        </div>

        <div className="mt-16 grid gap-6 lg:grid-cols-3">
          {JOURNEY.map((s, idx) => (
            <article
              key={s.title}
              className="relative overflow-hidden rounded-2xl border border-border bg-background p-8 transition hover:border-border-strong"
            >
              {/* 상단 보라 인디케이터 라인 */}
              <div
                aria-hidden
                className="absolute inset-x-0 top-0 h-px"
                style={{
                  background:
                    "linear-gradient(90deg, transparent 10%, rgba(103,80,164,0.45) 50%, transparent 90%)",
                }}
              />
              <div className="flex items-center justify-between">
                <p className="font-mono text-[11px] font-semibold uppercase tracking-[0.2em] text-brand">
                  Stage {String(idx + 1).padStart(2, "0")}
                </p>
                {idx < JOURNEY.length - 1 ? (
                  <span
                    className="hidden text-foreground-faint lg:inline"
                    aria-hidden
                  >
                    →
                  </span>
                ) : null}
              </div>
              <h3 className="mt-7 text-2xl font-semibold tracking-tight text-foreground">
                {s.title}
              </h3>
              <p className="mt-3 text-sm leading-relaxed text-foreground-muted">
                {s.body}
              </p>
            </article>
          ))}
        </div>
      </div>
    </section>
  );
}

type Msg = { from: "me" | "other" | "idol"; text: string };

const HOW_IDOL: Msg[] = [
  { from: "idol", text: "오늘 콘서트 너무 좋았어!" },
  { from: "idol", text: "다들 잘 들어갔지?" },
];
const HOW_FAN_A: Msg[] = [
  { from: "other", text: "오늘 콘서트 너무 좋았어!" },
  { from: "other", text: "다들 잘 들어갔지?" },
  { from: "me", text: "너무 행복했어요 ☺️" },
];
const HOW_FAN_B: Msg[] = [
  { from: "other", text: "오늘 콘서트 너무 좋았어!" },
  { from: "other", text: "다들 잘 들어갔지?" },
  { from: "me", text: "다음 콘서트는 언제예요?" },
];

function HowItWorks() {
  return (
    <section id="how" className="border-t border-border">
      <div className="mx-auto max-w-6xl px-6 py-24 sm:py-32">
        <div className="mx-auto max-w-2xl text-center">
          <p className="text-xs font-semibold uppercase tracking-[0.2em] text-brand">
            서비스 구조
          </p>
          <h2 className="mt-4 text-balance text-3xl font-semibold leading-tight tracking-tight text-foreground sm:text-4xl">
            1:1처럼 보이는,
            <br className="hidden sm:inline" />
            1:N 대화의 구조.
          </h2>
          <p className="mt-5 text-pretty text-base leading-relaxed text-foreground-muted sm:text-lg">
            아이돌의 한 마디는 응원하는 모든 팬에게 동일하게. 팬의 답장은 그
            아이돌에게만. 모든 팬은 자신만의 1:1 화면을 가집니다.
          </p>
        </div>

        <div className="mt-16 grid gap-4 md:grid-cols-3">
          <ChatPreview
            role="idol"
            title="아이돌 화면"
            caption="한 번 쓰면 — 응원하는 모든 팬에게."
            messages={HOW_IDOL}
          />
          <ChatPreview
            role="fan"
            title="팬 A의 화면"
            caption="1:1처럼 보이는 화면. 답장은 그 아이돌만 봅니다."
            messages={HOW_FAN_A}
          />
          <ChatPreview
            role="fan"
            title="팬 B의 화면"
            caption="같은 메시지를 받지만, 팬 사이 답장은 보이지 않아요."
            messages={HOW_FAN_B}
          />
        </div>
      </div>
    </section>
  );
}

function ChatPreview({
  role,
  title,
  caption,
  messages,
}: {
  role: "idol" | "fan";
  title: string;
  caption: string;
  messages: Msg[];
}) {
  return (
    <div className="overflow-hidden rounded-3xl border border-border bg-background shadow-[0_1px_0_rgba(0,0,0,0.02),0_30px_60px_-30px_rgba(103,80,164,0.18)]">
      <div className="flex items-center justify-between border-b border-border px-5 py-3">
        <span className="text-xs font-medium text-foreground-muted">
          {title}
        </span>
        <span
          className={
            role === "idol"
              ? "rounded-full bg-brand-soft px-2 py-0.5 text-[10px] font-semibold tracking-wider text-brand"
              : "rounded-full bg-surface-muted px-2 py-0.5 text-[10px] font-semibold tracking-wider text-foreground-subtle"
          }
        >
          {role === "idol" ? "IDOL" : "FAN"}
        </span>
      </div>
      <div className="min-h-[180px] space-y-2 px-5 py-6">
        {messages.map((m, i) => (
          <div
            key={i}
            className={`flex ${m.from === "me" ? "justify-end" : "justify-start"}`}
          >
            <div
              className={
                m.from === "me"
                  ? "max-w-[80%] rounded-2xl bg-brand px-3.5 py-2 text-sm text-brand-foreground"
                  : "max-w-[80%] rounded-2xl bg-surface-muted px-3.5 py-2 text-sm text-foreground"
              }
            >
              {m.text}
            </div>
          </div>
        ))}
      </div>
      <p className="border-t border-border bg-surface px-5 py-3 text-xs text-foreground-muted">
        {caption}
      </p>
    </div>
  );
}

function SiteFooter() {
  return (
    <footer className="border-t border-border">
      <div className="mx-auto flex max-w-6xl flex-col gap-4 px-6 py-10 text-sm text-foreground-muted sm:flex-row sm:items-center sm:justify-between">
        <p>© 2026 앙코르</p>
        <div className="flex gap-6">
          <a
            href="mailto:hello@encore.app"
            className="transition hover:text-foreground"
          >
            문의
          </a>
          <a href="#" className="transition hover:text-foreground">
            이용약관
          </a>
          <a href="#" className="transition hover:text-foreground">
            개인정보처리방침
          </a>
        </div>
      </div>
    </footer>
  );
}
