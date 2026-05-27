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
        <Finale />
      </main>
    </>
  );
}

function SiteHeader() {
  return (
    <header className="fixed inset-x-0 top-0 z-50 border-b border-outline-soft bg-bg/70 backdrop-blur-xl">
      <div className="mx-auto flex h-14 max-w-6xl items-center justify-between px-6">
        <Link
          href="#top"
          className="text-base font-semibold tracking-tight text-fg"
        >
          앙코르
        </Link>
        <nav className="hidden items-center gap-7 text-sm text-fg-muted md:flex">
          <a href="#ways" className="transition hover:text-fg">
            함께하는 방식
          </a>
          <a href="#character" className="transition hover:text-fg">
            캐릭터
          </a>
          <a href="#journey" className="transition hover:text-fg">
            여정
          </a>
          <a href="#how" className="transition hover:text-fg">
            구조
          </a>
        </nav>
        <a
          href="mailto:hello@encore.app?subject=아이돌%20활동%20문의"
          className="rounded-full border border-outline px-3.5 py-1.5 text-sm font-medium text-fg transition hover:border-primary hover:text-primary"
        >
          아이돌로 활동하기
        </a>
      </div>
    </header>
  );
}

/* ─────────────────────────────────────────────────────
   섹션 공통 헬퍼 — 풀스크린 + 배경 그라데이션
   ───────────────────────────────────────────────────── */
function Section({
  id,
  background,
  children,
}: {
  id: string;
  background: string;
  children: React.ReactNode;
}) {
  return (
    <section
      id={id}
      className="snap-section relative flex flex-col items-center justify-center overflow-hidden px-6 pt-20 pb-16 sm:pt-24"
      style={{ background }}
    >
      {children}
    </section>
  );
}

/* ─────────────────────────────────────────────────────
   1. Hero
   ───────────────────────────────────────────────────── */
function Hero() {
  return (
    <Section
      id="top"
      background="radial-gradient(ellipse 80% 60% at 50% 0%, rgba(199,112,255,0.28), transparent 65%), radial-gradient(ellipse 50% 40% at 25% 80%, rgba(0,229,255,0.10), transparent 60%), #0a0a0f"
    >
      <div className="mx-auto w-full max-w-3xl text-center">
        <div className="mb-7 inline-flex items-center gap-2 rounded-full border border-outline bg-surface/60 px-3 py-1 text-xs font-medium text-fg-muted backdrop-blur">
          <span className="h-1.5 w-1.5 rounded-full bg-primary shadow-[0_0_12px_rgba(199,112,255,0.8)]" />
          함께 자라는 아이돌의 모든 순간
        </div>

        <h1 className="text-balance text-5xl font-bold leading-[1.05] tracking-tight text-fg sm:text-7xl">
          당신의 아이돌,
          <br />
          <span className="bg-gradient-to-r from-primary via-tertiary to-primary bg-clip-text text-transparent">
            함께 자라요.
          </span>
        </h1>

        <p className="mt-8 text-pretty text-lg leading-relaxed text-fg-muted sm:text-xl">
          지켜보고 · 대화하고 · 후원하며.
          <br />
          작은 응원이 한 명의 아이돌을 무대로 데려갑니다.
        </p>

        <div className="mt-10 flex flex-col items-center justify-center gap-3 sm:flex-row">
          <a
            href="#finale"
            className="inline-flex h-12 items-center justify-center rounded-full bg-primary px-7 text-sm font-semibold text-primary-on shadow-[0_0_32px_-4px_rgba(199,112,255,0.55)] transition hover:bg-primary-hover hover:shadow-[0_0_40px_-2px_rgba(199,112,255,0.75)]"
          >
            출시 알림 받기
          </a>
          <a
            href="mailto:hello@encore.app?subject=아이돌%20활동%20문의"
            className="inline-flex h-12 items-center justify-center rounded-full border border-outline px-6 text-sm font-medium text-fg transition hover:border-primary hover:text-primary"
          >
            아이돌로 활동하기 →
          </a>
        </div>

        <ul className="mt-16 grid grid-cols-2 gap-x-8 gap-y-5 text-sm sm:flex sm:justify-center sm:gap-x-12">
          {[
            { k: "지켜보기", i: "01" },
            { k: "대화하기", i: "02" },
            { k: "후원하기", i: "03" },
            { k: "성장시키기", i: "04" },
          ].map((it) => (
            <li key={it.k} className="inline-flex items-center gap-2">
              <span className="font-mono text-[11px] tracking-wider text-fg-faint">
                {it.i}
              </span>
              <span className="font-medium text-fg">{it.k}</span>
            </li>
          ))}
        </ul>
      </div>

      {/* 다운 화살표 — 인터랙션 유도 */}
      <a
        href="#ways"
        aria-label="다음 섹션으로 이동"
        className="animate-bounce-down absolute bottom-8 left-1/2 flex h-12 w-12 items-center justify-center rounded-full border border-outline bg-surface/70 text-fg-muted backdrop-blur transition hover:border-primary hover:text-primary"
      >
        <svg
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth="2"
          strokeLinecap="round"
          strokeLinejoin="round"
          className="h-5 w-5"
          aria-hidden
        >
          <polyline points="6 9 12 15 18 9" />
        </svg>
      </a>
    </Section>
  );
}

/* ─────────────────────────────────────────────────────
   2. Ways — 함께하는 4가지 방식
   ───────────────────────────────────────────────────── */
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
    <Section
      id="ways"
      background="radial-gradient(ellipse 70% 55% at 100% 100%, rgba(0,229,255,0.16), transparent 60%), radial-gradient(ellipse 40% 30% at 0% 0%, rgba(199,112,255,0.10), transparent 60%), #13131a"
    >
      <div className="mx-auto w-full max-w-6xl">
        <div className="mx-auto max-w-2xl text-center">
          <p className="text-xs font-semibold uppercase tracking-[0.3em] text-secondary">
            함께하는 방식
          </p>
          <h2 className="mt-4 text-balance text-4xl font-bold leading-tight tracking-tight text-fg sm:text-5xl">
            네 가지 방식으로,
            <br />한 명의 아이돌과.
          </h2>
          <p className="mt-5 text-pretty text-base leading-relaxed text-fg-muted sm:text-lg">
            앙코르는 매일의 작은 순간이 한 명의 아이돌을 무대로 데려가는
            자리입니다.
          </p>
        </div>

        <div className="mt-14 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
          {WAYS.map((w) => (
            <article
              key={w.index}
              className="group relative flex flex-col gap-5 rounded-2xl border border-outline-soft bg-surface p-6 transition hover:border-primary hover:bg-surface-2"
            >
              <header className="flex items-center justify-between">
                <span className="font-mono text-[11px] tracking-wider text-fg-faint">
                  {w.index}
                </span>
                {w.badge ? (
                  <span className="rounded-full bg-primary-container px-2 py-0.5 text-[10px] font-semibold tracking-wider text-primary-container-on">
                    {w.badge}
                  </span>
                ) : null}
              </header>
              <h3 className="text-xl font-semibold tracking-tight text-fg">
                {w.title}
              </h3>
              <p className="text-sm leading-relaxed text-fg-muted">{w.body}</p>
            </article>
          ))}
        </div>
      </div>
    </Section>
  );
}

/* ─────────────────────────────────────────────────────
   3. Character — 2.5D 캐릭터 Coming Soon
   ───────────────────────────────────────────────────── */
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
    <Section
      id="character"
      background="radial-gradient(circle 50% at 70% 50%, rgba(255,61,161,0.22), transparent 55%), radial-gradient(circle 45% at 20% 30%, rgba(199,112,255,0.24), transparent 55%), #0a0a0f"
    >
      <div className="mx-auto w-full max-w-6xl">
        <div className="grid items-center gap-10 lg:grid-cols-2 lg:gap-20">
          <div>
            <p className="text-xs font-semibold uppercase tracking-[0.3em] text-tertiary">
              곧 만나요
            </p>
            <h2 className="mt-4 text-balance text-4xl font-bold leading-tight tracking-tight text-fg sm:text-5xl">
              채팅에 맞춰 움직이는,
              <br />
              <span className="bg-gradient-to-r from-tertiary to-primary bg-clip-text text-transparent">
                아이돌의 분신.
              </span>
            </h2>
            <p className="mt-5 text-pretty text-base leading-relaxed text-fg-muted sm:text-lg">
              곧 도입될 2.5D 맞춤 캐릭터로, 당신의 아이돌이 화면 너머에서 살아
              움직입니다. 메시지 한 줄, 작은 후원, 그리고 함께한 시간이
              캐릭터에 그대로 쌓여요.
            </p>

            <ul className="mt-8 space-y-4">
              {CHARACTER_FEATURES.map((f) => (
                <li key={f.title} className="flex gap-4">
                  <span
                    aria-hidden
                    className="mt-2.5 h-1.5 w-1.5 shrink-0 rounded-full bg-primary shadow-[0_0_10px_rgba(199,112,255,0.8)]"
                  />
                  <div>
                    <p className="font-semibold text-fg">{f.title}</p>
                    <p className="mt-1 text-sm leading-relaxed text-fg-muted">
                      {f.body}
                    </p>
                  </div>
                </li>
              ))}
            </ul>

            <p className="mt-8 text-xs text-fg-faint">
              * 1차 출시 이후 단계적으로 도입됩니다.
            </p>
          </div>

          <div className="relative">
            <CharacterPreview />
          </div>
        </div>
      </div>
    </Section>
  );
}

function CharacterPreview() {
  return (
    <div className="relative aspect-[4/5] w-full max-w-md overflow-hidden rounded-3xl border border-outline bg-surface">
      {/* 보라/핑크 블러 글로우 */}
      <div
        aria-hidden
        className="absolute left-1/2 top-1/2 h-[420px] w-[420px] -translate-x-1/2 -translate-y-1/2 rounded-full opacity-70 blur-3xl"
        style={{
          background:
            "radial-gradient(circle, rgba(199,112,255,0.45) 0%, rgba(255,61,161,0.25) 40%, transparent 70%)",
        }}
      />

      <div className="absolute left-1/2 top-[58%] -translate-x-1/2 -translate-y-1/2">
        <svg
          viewBox="0 0 200 240"
          className="h-56 w-44 sm:h-72 sm:w-56"
          aria-hidden
        >
          <defs>
            <linearGradient id="charGrad" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0" stopColor="#FF3DA1" />
              <stop offset="1" stopColor="#C770FF" />
            </linearGradient>
          </defs>
          <ellipse
            cx="100"
            cy="230"
            rx="95"
            ry="35"
            fill="url(#charGrad)"
            opacity="0.85"
          />
          <rect
            x="85"
            y="140"
            width="30"
            height="55"
            fill="url(#charGrad)"
            opacity="0.85"
          />
          <circle cx="100" cy="95" r="52" fill="url(#charGrad)" />
          <ellipse
            cx="85"
            cy="75"
            rx="14"
            ry="8"
            fill="#FFFFFF"
            opacity="0.25"
          />
        </svg>
      </div>

      <div className="absolute left-5 top-6 max-w-[200px] rounded-2xl rounded-bl-md border border-outline-soft bg-bg-elevated/90 px-3.5 py-2.5 backdrop-blur">
        <p className="text-xs font-medium text-fg">
          오늘 콘서트 너무 좋았어 ✨
        </p>
        <p className="mt-1 text-[10px] text-fg-faint">아이돌의 한 마디</p>
      </div>

      <div className="absolute right-5 top-[40%] flex flex-col items-end gap-2">
        <span className="rounded-full border border-outline-soft bg-bg-elevated/80 px-3 py-1 text-[11px] font-medium text-fg-muted backdrop-blur">
          → 미소
        </span>
        <span className="rounded-full border border-outline-soft bg-bg-elevated/80 px-3 py-1 text-[11px] font-medium text-fg-muted backdrop-blur">
          → 손 흔들기
        </span>
      </div>

      <div className="absolute bottom-5 left-5">
        <span className="rounded-full bg-primary px-2.5 py-1 text-[10px] font-semibold tracking-[0.15em] text-primary-on">
          v0.1 PREVIEW
        </span>
      </div>

      <div className="absolute bottom-5 right-5 text-right">
        <p className="text-[10px] font-medium uppercase tracking-wider text-fg-faint">
          Coming
        </p>
        <p className="font-mono text-xs font-semibold text-fg">2026 →</p>
      </div>
    </div>
  );
}

/* ─────────────────────────────────────────────────────
   4. Journey — Stage 01~03
   ───────────────────────────────────────────────────── */
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
    <Section
      id="journey"
      background="linear-gradient(135deg, rgba(0,229,255,0.12) 0%, transparent 35%, transparent 65%, rgba(199,112,255,0.16) 100%), #13131a"
    >
      <div className="mx-auto w-full max-w-6xl">
        <div className="mx-auto max-w-2xl text-center">
          <p className="text-xs font-semibold uppercase tracking-[0.3em] text-secondary">
            함께 가는 길
          </p>
          <h2 className="mt-4 text-balance text-4xl font-bold leading-tight tracking-tight text-fg sm:text-5xl">
            디지털에서 만나,
            <br />
            <span className="bg-gradient-to-r from-secondary to-primary bg-clip-text text-transparent">
              무대에서 마주봐요.
            </span>
          </h2>
          <p className="mt-5 text-pretty text-base leading-relaxed text-fg-muted sm:text-lg">
            매일의 작은 대화로 시작해, 첫 무대와 그 너머까지. 앙코르는 디지털과
            오프라인을 잇는 자리입니다.
          </p>
        </div>

        <div className="mt-14 grid gap-6 lg:grid-cols-3">
          {JOURNEY.map((s, idx) => (
            <article
              key={s.title}
              className="relative overflow-hidden rounded-2xl border border-outline-soft bg-surface p-8 transition hover:border-secondary"
            >
              <div
                aria-hidden
                className="absolute inset-x-0 top-0 h-px"
                style={{
                  background:
                    "linear-gradient(90deg, transparent 10%, rgba(0,229,255,0.6) 50%, transparent 90%)",
                }}
              />
              <div className="flex items-center justify-between">
                <p className="font-mono text-[11px] font-semibold uppercase tracking-[0.3em] text-secondary">
                  Stage {String(idx + 1).padStart(2, "0")}
                </p>
                {idx < JOURNEY.length - 1 ? (
                  <span
                    className="hidden text-fg-faint lg:inline"
                    aria-hidden
                  >
                    →
                  </span>
                ) : null}
              </div>
              <h3 className="mt-6 text-2xl font-semibold tracking-tight text-fg">
                {s.title}
              </h3>
              <p className="mt-3 text-sm leading-relaxed text-fg-muted">
                {s.body}
              </p>
            </article>
          ))}
        </div>
      </div>
    </Section>
  );
}

/* ─────────────────────────────────────────────────────
   5. HowItWorks — 1:N 채팅 메커니즘
   ───────────────────────────────────────────────────── */
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
    <Section
      id="how"
      background="radial-gradient(ellipse 65% 50% at 50% 50%, rgba(199,112,255,0.16), transparent 60%), radial-gradient(ellipse 40% 30% at 100% 0%, rgba(0,229,255,0.12), transparent 60%), #0a0a0f"
    >
      <div className="mx-auto w-full max-w-6xl">
        <div className="mx-auto max-w-2xl text-center">
          <p className="text-xs font-semibold uppercase tracking-[0.3em] text-primary">
            서비스 구조
          </p>
          <h2 className="mt-4 text-balance text-4xl font-bold leading-tight tracking-tight text-fg sm:text-5xl">
            1:1처럼 보이는,
            <br />
            <span className="bg-gradient-to-r from-primary to-secondary bg-clip-text text-transparent">
              1:N 대화의 구조.
            </span>
          </h2>
          <p className="mt-5 text-pretty text-base leading-relaxed text-fg-muted sm:text-lg">
            아이돌의 한 마디는 응원하는 모든 팬에게 동일하게. 팬의 답장은 그
            아이돌에게만. 모든 팬은 자신만의 1:1 화면을 가집니다.
          </p>
        </div>

        <div className="mt-14 grid gap-4 md:grid-cols-3">
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
    </Section>
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
    <div className="overflow-hidden rounded-2xl border border-outline-soft bg-surface">
      <div className="flex items-center justify-between border-b border-outline-soft px-5 py-3">
        <span className="text-xs font-medium text-fg-muted">{title}</span>
        <span
          className={
            role === "idol"
              ? "rounded-full bg-primary-container px-2 py-0.5 text-[10px] font-semibold tracking-wider text-primary-container-on"
              : "rounded-full bg-surface-3 px-2 py-0.5 text-[10px] font-semibold tracking-wider text-fg-muted"
          }
        >
          {role === "idol" ? "IDOL" : "FAN"}
        </span>
      </div>
      <div className="min-h-[160px] space-y-2 px-5 py-5">
        {messages.map((m, i) => (
          <div
            key={i}
            className={`flex ${m.from === "me" ? "justify-end" : "justify-start"}`}
          >
            <div
              className={
                m.from === "me"
                  ? "max-w-[80%] rounded-2xl bg-primary-container px-3.5 py-2 text-sm text-primary-container-on"
                  : "max-w-[80%] rounded-2xl bg-surface-2 px-3.5 py-2 text-sm text-fg"
              }
            >
              {m.text}
            </div>
          </div>
        ))}
      </div>
      <p className="border-t border-outline-soft bg-bg-elevated px-5 py-3 text-xs text-fg-muted">
        {caption}
      </p>
    </div>
  );
}

/* ─────────────────────────────────────────────────────
   6. Finale — CTA + Footer 통합 풀스크린
   ───────────────────────────────────────────────────── */
function Finale() {
  return (
    <section
      id="finale"
      className="snap-section relative flex flex-col overflow-hidden"
      style={{
        background:
          "radial-gradient(ellipse 80% 60% at 50% 100%, rgba(199,112,255,0.45), transparent 70%), radial-gradient(ellipse 60% 40% at 50% 0%, rgba(255,61,161,0.20), transparent 70%), #0a0a0f",
      }}
    >
      <div className="flex flex-1 items-center justify-center px-6 pt-20">
        <div className="mx-auto w-full max-w-2xl text-center">
          <p className="text-xs font-semibold uppercase tracking-[0.3em] text-primary">
            앙코르
          </p>
          <h2 className="mt-5 text-balance text-5xl font-bold leading-[1.05] tracking-tight text-fg sm:text-6xl">
            함께 자라는 첫
            <br />
            <span className="bg-gradient-to-r from-tertiary via-primary to-secondary bg-clip-text text-transparent">
              앙코르를 외쳐요.
            </span>
          </h2>
          <p className="mt-6 text-pretty text-lg leading-relaxed text-fg-muted">
            출시 소식을 가장 먼저 받아보세요.
            <br />
            팬과 아이돌, 모두 환영합니다.
          </p>

          <div className="mt-10 flex flex-col items-center justify-center gap-3 sm:flex-row">
            <a
              href="mailto:hello@encore.app?subject=출시%20알림%20신청"
              className="inline-flex h-12 items-center justify-center rounded-full bg-primary px-7 text-sm font-semibold text-primary-on shadow-[0_0_36px_-2px_rgba(199,112,255,0.7)] transition hover:bg-primary-hover"
            >
              출시 알림 받기
            </a>
            <a
              href="mailto:hello@encore.app?subject=아이돌%20활동%20문의"
              className="inline-flex h-12 items-center justify-center rounded-full border border-outline px-6 text-sm font-medium text-fg transition hover:border-primary hover:text-primary"
            >
              아이돌로 활동하기 →
            </a>
          </div>
        </div>
      </div>

      <footer className="border-t border-outline-soft px-6 py-6 backdrop-blur">
        <div className="mx-auto flex max-w-6xl flex-col gap-3 text-sm text-fg-muted sm:flex-row sm:items-center sm:justify-between">
          <p>© 2026 앙코르</p>
          <div className="flex gap-6">
            <a
              href="mailto:hello@encore.app"
              className="transition hover:text-fg"
            >
              문의
            </a>
            <a href="#" className="transition hover:text-fg">
              이용약관
            </a>
            <a href="#" className="transition hover:text-fg">
              개인정보처리방침
            </a>
          </div>
        </div>
      </footer>
    </section>
  );
}
