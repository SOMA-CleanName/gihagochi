import { CharacterPhoneSlides } from "./_components/character-phone-slides";
import { PartnerContact } from "./_components/partner-contact";
import { SiteFooter } from "./_components/site-footer";
import { SiteHeader } from "./_components/site-header";
import { TrackedLink } from "./_components/tracked-link";
import { WaitlistForm } from "./_components/waitlist-form";

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
        <Partners />
        <Finale />
      </main>
    </>
  );
}

/* ─────────────────────────────────────────────────────
   섹션 공통 래퍼 — 풀스크린 + 배경
   ───────────────────────────────────────────────────── */
function Section({
  id,
  background,
  children,
  className = "",
}: {
  id: string;
  background: string;
  children: React.ReactNode;
  className?: string;
}) {
  return (
    <section
      id={id}
      className={`snap-section relative flex flex-col items-center justify-center overflow-hidden px-6 pt-24 pb-16 ${className}`}
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
      background="radial-gradient(ellipse 80% 60% at 50% 0%, rgba(199,112,255,0.18), transparent 65%), radial-gradient(ellipse 50% 40% at 25% 80%, rgba(0,229,255,0.06), transparent 60%)"
    >
      <div className="mx-auto w-full max-w-3xl text-center">
        <span
          className="animate-fade-up inline-flex items-center gap-2 rounded-full border border-primary/35 bg-primary/10 px-4 py-1.5 text-xs font-medium text-primary-container-on backdrop-blur-sm"
          style={{ animationDelay: "0ms" }}
        >
          <span className="h-1.5 w-1.5 rounded-full bg-primary shadow-[0_0_8px_var(--color-primary)]" />
          지하돌 팬덤 · 사전신청 받는 중
        </span>

        <h1
          className="animate-fade-up mt-7 text-balance text-5xl font-semibold leading-[1.1] tracking-tight text-fg sm:text-7xl"
          style={{ animationDelay: "90ms" }}
        >
          당신의 아이돌,
          <br />
          <span className="text-neon">함께 자라요.</span>
        </h1>

        <p
          className="animate-fade-up mt-8 text-pretty text-lg leading-relaxed text-fg-muted sm:text-xl"
          style={{ animationDelay: "180ms" }}
        >
          지켜보고, 대화하고, 후원하며.
          <br />
          작은 응원이 한 명의 아이돌을 무대로 데려갑니다.
        </p>

        <div
          className="animate-fade-up mt-10 flex flex-col items-center justify-center gap-3 sm:flex-row"
          style={{ animationDelay: "270ms" }}
        >
          <TrackedLink
            href="#finale"
            label="hero_primary"
            className="animate-neon-pulse w-full rounded-full bg-primary px-7 py-3.5 text-sm font-semibold text-primary-on transition hover:bg-primary-hover sm:w-auto"
          >
            사전신청 하기 →
          </TrackedLink>
          <TrackedLink
            href="#how"
            label="hero_secondary"
            className="w-full rounded-full border border-outline px-7 py-3.5 text-sm font-semibold text-fg transition hover:border-primary hover:text-primary sm:w-auto"
          >
            어떻게 작동하나요
          </TrackedLink>
        </div>
      </div>

      {/* 다운 화살표 — 인터랙션 유도 */}
      <a
        href="#ways"
        aria-label="다음 섹션으로 이동"
        className="animate-bounce-down absolute bottom-10 left-1/2 flex h-11 w-11 items-center justify-center rounded-full border border-outline text-fg-muted transition hover:border-primary hover:text-primary"
      >
        <svg
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth="1.8"
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
   2. Ways — 함께하는 4가지 방식 (2x2 grid)
   ───────────────────────────────────────────────────── */
const WAYS = [
  {
    title: "지켜보기",
    body: "매일의 채팅과 일상이 천천히 쌓입니다. 한 명의 아이돌이 자라는 모든 순간을, 처음부터 함께 봅니다.",
  },
  {
    title: "대화하기",
    body: "팬의 메시지는 그 아이돌에게만. 아이돌의 한 마디는 응원하는 모두에게. 가장 가까운 거리에서 매일 안부를 묻습니다.",
  },
  {
    title: "후원하기",
    note: "준비 중",
    body: "작은 응원이 모여 무대가 됩니다. 출시 이후 단계적으로 열리는 후원으로, 아이돌의 다음 길에 손을 보탭니다.",
  },
  {
    title: "성장시키기",
    body: "당신과 함께한 시간이 아이돌의 다음 챕터가 됩니다. 첫 무대, 첫 콘서트, 그 너머의 여정까지.",
  },
] satisfies ReadonlyArray<{
  title: string;
  body: string;
  note?: string;
}>;

function Ways() {
  return (
    <Section
      id="ways"
      background="radial-gradient(ellipse 65% 50% at 100% 100%, rgba(0,229,255,0.10), transparent 60%), radial-gradient(ellipse 40% 30% at 0% 0%, rgba(199,112,255,0.06), transparent 60%)"
    >
      <div className="mx-auto w-full max-w-5xl">
        <div className="max-w-2xl">
          <h2 className="text-balance text-4xl font-semibold leading-tight tracking-tight text-fg sm:text-5xl">
            네 가지 방식으로,
            <br />한 명의 아이돌과.
          </h2>
          <p className="mt-5 text-pretty text-base leading-relaxed text-fg-muted sm:text-lg">
            앙코르는 매일의 작은 순간이 한 명의 아이돌을 무대로 데려가는
            자리입니다.
          </p>
        </div>

        <div className="mt-12 grid gap-4 sm:grid-cols-2">
          {WAYS.map((w) => (
            <article
              key={w.title}
              className="text-card relative rounded-2xl border border-outline-soft transition hover:border-outline"
            >
              <div className="flex items-baseline justify-between">
                <h3 className="text-xl font-semibold tracking-tight text-fg">
                  {w.title}
                </h3>
                {w.note ? (
                  <span className="text-[11px] font-medium text-fg-faint">
                    {w.note}
                  </span>
                ) : null}
              </div>
              <p className="mt-3 text-sm leading-relaxed text-fg-muted">
                {w.body}
              </p>
            </article>
          ))}
        </div>
      </div>
    </Section>
  );
}

/* ─────────────────────────────────────────────────────
   3. Character — 2.5D 캐릭터 (단계적 도입)
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
    body: "후원과 함께한 시간이 쌓이면 의상과 공간, 표현이 단계적으로 풍부해집니다.",
  },
] as const;

function Character() {
  return (
    <Section
      id="character"
      background="radial-gradient(circle 50% at 70% 50%, rgba(255,61,161,0.14), transparent 55%), radial-gradient(circle 45% at 20% 30%, rgba(199,112,255,0.14), transparent 55%)"
    >
      <div className="mx-auto w-full max-w-6xl">
        <div className="grid items-center gap-12 lg:grid-cols-2 lg:gap-20">
          <div>
            <h2 className="text-balance text-4xl font-semibold leading-tight tracking-tight text-fg sm:text-5xl">
              채팅에 맞춰 움직이는,
              <br />
              아이돌의 분신.
            </h2>
            <p className="mt-5 text-pretty text-base leading-relaxed text-fg-muted sm:text-lg">
              2.5D 맞춤 캐릭터로, 당신의 아이돌이 화면 너머에서 살아 움직이는
              경험을 준비하고 있어요. 메시지 한 줄, 작은 후원, 함께한 시간이
              그대로 캐릭터에 쌓여요.
            </p>

            <dl className="mt-10 space-y-7">
              {CHARACTER_FEATURES.map((f) => (
                <div key={f.title}>
                  <dt className="text-base font-semibold text-fg">
                    {f.title}
                  </dt>
                  <dd className="mt-1.5 text-sm leading-relaxed text-fg-muted">
                    {f.body}
                  </dd>
                </div>
              ))}
            </dl>

            <p className="mt-10 text-xs text-fg-faint">
              출시 이후 단계적으로 도입됩니다.
            </p>
          </div>

          <div className="relative flex justify-center lg:justify-end">
            {/* 보라/핑크 글로우 — 핸드폰 mockup 뒤 */}
            <div
              aria-hidden
              className="pointer-events-none absolute inset-0 -z-0"
              style={{
                background:
                  "radial-gradient(circle at 50% 50%, rgba(199,112,255,0.35) 0%, rgba(255,61,161,0.18) 40%, transparent 70%)",
                filter: "blur(40px)",
              }}
            />
            <CharacterPhoneSlides />
          </div>
        </div>
      </div>
    </Section>
  );
}

/* ─────────────────────────────────────────────────────
   4. Journey — 세 단계의 여정
   ───────────────────────────────────────────────────── */
const JOURNEY = [
  {
    n: "01",
    title: "디지털에서 만나",
    body: "매일의 채팅으로 가까워져요. 응원하는 시간이 그 아이돌과 당신만의 기록으로 쌓입니다.",
  },
  {
    n: "02",
    title: "함께 자라요",
    body: "후원과 응원이 아이돌의 다음 길에 손을 보탭니다. 변화를 가장 가까이서 지켜봐요.",
  },
  {
    n: "03",
    title: "무대에서 마주봐요",
    body: "디지털에서 쌓은 시간이 첫 무대, 첫 콘서트, 그리고 직접 만나는 자리로 이어집니다.",
  },
] as const;

function Journey() {
  return (
    <Section
      id="journey"
      background="linear-gradient(135deg, rgba(0,229,255,0.08) 0%, transparent 35%, transparent 65%, rgba(199,112,255,0.10) 100%)"
    >
      <div className="mx-auto w-full max-w-5xl">
        <div className="max-w-2xl">
          <h2 className="text-balance text-4xl font-semibold leading-tight tracking-tight text-fg sm:text-5xl">
            디지털에서 만나,
            <br />
            무대에서 마주봐요.
          </h2>
          <p className="mt-5 text-pretty text-base leading-relaxed text-fg-muted sm:text-lg">
            매일의 작은 대화로 시작해, 첫 무대와 그 너머까지. 앙코르는 디지털과
            오프라인을 잇는 자리입니다.
          </p>
        </div>

        <ol className="mt-14 space-y-6 sm:mt-16">
          {JOURNEY.map((s) => (
            <li
              key={s.n}
              className="text-card grid gap-3 sm:grid-cols-[6rem_1fr] sm:gap-8"
            >
              <span className="font-mono text-sm text-fg-faint">{s.n}</span>
              <div>
                <h3 className="text-2xl font-semibold tracking-tight text-fg sm:text-3xl">
                  {s.title}
                </h3>
                <p className="mt-2 text-base leading-relaxed text-fg-muted">
                  {s.body}
                </p>
              </div>
            </li>
          ))}
        </ol>
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
  { from: "me", text: "너무 행복했어요" },
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
      background="radial-gradient(ellipse 60% 45% at 50% 50%, rgba(199,112,255,0.10), transparent 60%), radial-gradient(ellipse 40% 30% at 100% 0%, rgba(0,229,255,0.06), transparent 60%)"
    >
      <div className="mx-auto w-full max-w-6xl">
        <div className="max-w-2xl">
          <h2 className="text-balance text-4xl font-semibold leading-tight tracking-tight text-fg sm:text-5xl">
            1:1처럼 보이는,
            <br />
            1:N 대화의 구조.
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
            caption="한 번 쓰면, 응원하는 모든 팬에게."
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
            caption="같은 메시지를 받지만, 팬 사이 답장은 보이지 않습니다."
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
    <div className="text-card relative overflow-hidden rounded-2xl border border-outline-soft p-0">
      <div className="flex items-center justify-between border-b border-outline-soft px-5 py-3">
        <span className="text-xs font-medium text-fg-muted">{title}</span>
        <span className="text-[10px] font-medium text-fg-faint">
          {role === "idol" ? "아이돌" : "팬"}
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
      <p className="border-t border-outline-soft px-5 py-3 text-xs text-fg-muted">
        {caption}
      </p>
    </div>
  );
}

/* ─────────────────────────────────────────────────────
   6. Partners — 소속사/기획사 B2B
   ───────────────────────────────────────────────────── */
const PARTNER_POINTS = [
  {
    title: "새로운 팬 접점",
    body: "소속 아이돌의 일상이 매일의 채팅으로 팬과 이어집니다. 데뷔 전·후 어느 단계든, 디지털에서 팬덤을 먼저 만듭니다.",
  },
  {
    title: "투명한 수익 셰어",
    body: "후원·구독에서 발생하는 수익을 소속사와 함께 나눕니다. 정산 기준은 명확하게, 데이터는 투명하게 공유합니다.",
  },
  {
    title: "함께 키우는 IP",
    body: "쌓인 팬과의 시간이 첫 무대, 첫 콘서트로 이어집니다. 디지털 팬덤을 오프라인 IP로 확장하는 파트너가 됩니다.",
  },
] as const;

function Partners() {
  return (
    <Section
      id="partners"
      background="radial-gradient(ellipse 60% 45% at 0% 100%, rgba(0,229,255,0.10), transparent 60%), radial-gradient(ellipse 50% 40% at 100% 0%, rgba(199,112,255,0.10), transparent 60%)"
    >
      <div className="mx-auto w-full max-w-5xl">
        <div className="max-w-2xl">
          <span className="inline-flex items-center gap-2 rounded-full border border-secondary/35 bg-secondary/10 px-4 py-1.5 text-xs font-medium text-secondary-container-on backdrop-blur-sm">
            소속사 · 기획사 파트너
          </span>
          <h2 className="mt-6 text-balance text-4xl font-semibold leading-tight tracking-tight text-fg sm:text-5xl">
            소속 아이돌의 다음 무대,
            <br />
            함께 만들어요.
          </h2>
          <p className="mt-5 text-pretty text-base leading-relaxed text-fg-muted sm:text-lg">
            앙코르는 소속사와 함께 디지털 팬덤을 만들고, 그 성장을 오프라인
            무대로 잇는 파트너입니다. 팬 접점·수익 셰어·IP 확장을 함께
            설계해요.
          </p>
        </div>

        <div className="mt-12 grid gap-4 sm:grid-cols-3">
          {PARTNER_POINTS.map((p) => (
            <article
              key={p.title}
              className="text-card rounded-2xl border border-outline-soft transition hover:border-outline"
            >
              <h3 className="text-lg font-semibold tracking-tight text-fg">
                {p.title}
              </h3>
              <p className="mt-3 text-sm leading-relaxed text-fg-muted">
                {p.body}
              </p>
            </article>
          ))}
        </div>

        <div className="mt-12 rounded-2xl border border-outline-soft bg-surface-2/60 p-6 backdrop-blur-md sm:p-8">
          <h3 className="text-xl font-semibold tracking-tight text-fg">
            파트너십 문의
          </h3>
          <p className="mt-2 text-sm leading-relaxed text-fg-muted">
            소속 아이돌과 함께할 소속사·기획사를 찾고 있어요. 아래 채널로
            편하게 연락 주세요. 제휴 자료와 데모를 보내드립니다.
          </p>
          <div className="mt-6">
            <PartnerContact />
          </div>
        </div>
      </div>
    </Section>
  );
}

/* ─────────────────────────────────────────────────────
   7. Finale — CTA + Footer
   ───────────────────────────────────────────────────── */
function Finale() {
  return (
    <section
      id="finale"
      className="snap-section relative flex flex-col overflow-hidden"
      style={{
        background:
          "radial-gradient(ellipse 70% 55% at 50% 100%, rgba(199,112,255,0.28), transparent 70%), radial-gradient(ellipse 50% 35% at 50% 0%, rgba(255,61,161,0.12), transparent 70%)",
      }}
    >
      <div className="flex flex-1 items-center justify-center px-6 pt-24 pb-12">
        <div className="mx-auto w-full max-w-2xl text-center">
          <h2 className="text-balance text-5xl font-semibold leading-[1.05] tracking-tight text-fg sm:text-6xl">
            함께 자라는 첫 무대,
            <br />
            <span className="text-neon">앙코르를 외쳐요.</span>
          </h2>
          <p className="mt-6 text-pretty text-lg leading-relaxed text-fg-muted">
            함께 무대를 만들 아이돌과 소속사를 찾고 있어요.
            <br />
            지금 합류하거나, 편하게 문의 주세요.
          </p>

          <WaitlistForm />
        </div>
      </div>

      <SiteFooter />
    </section>
  );
}
