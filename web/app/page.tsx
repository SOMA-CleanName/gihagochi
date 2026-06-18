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
        <Why />
        <Product />
        <HowItWorks />
        <Partners />
        <Process />
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
   1. Hero — B2B (소속사·아이돌 대상)
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
          지하돌 팬덤 플랫폼 · 파트너 소속사 모집 중
        </span>

        <h1
          className="animate-fade-up mt-7 text-balance text-5xl font-semibold leading-[1.1] tracking-tight text-fg sm:text-7xl"
          style={{ animationDelay: "90ms" }}
        >
          소속 아이돌의 첫 팬덤,
          <br />
          <span className="text-neon">디지털에서 시작해요.</span>
        </h1>

        <p
          className="animate-fade-up mt-8 text-pretty text-lg leading-relaxed text-fg-muted sm:text-xl"
          style={{ animationDelay: "180ms" }}
        >
          입점 0원, 멤버 부담 없이. 매일의 채팅으로 팬을 모으고,
          <br className="hidden sm:block" />
          후원으로 수익을 나눕니다. 디지털 팬덤을 무대로 잇는 파트너, 앙코르.
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
            15분 데모 미팅 →
          </TrackedLink>
          <TrackedLink
            href="#how"
            label="hero_secondary"
            className="w-full rounded-full border border-outline px-7 py-3.5 text-sm font-semibold text-fg transition hover:border-primary hover:text-primary sm:w-auto"
          >
            작동 방식 보기
          </TrackedLink>
        </div>

        <p
          className="animate-fade-up mt-6 text-xs text-fg-faint"
          style={{ animationDelay: "360ms" }}
        >
          입점비·개발비 없음 · 후원 매출 수익 셰어 · 파일럿 1팀으로 가볍게 시작
        </p>
      </div>

      <a
        href="#why"
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
   2. Why — 문제·기회 (지하돌의 현실)
   ───────────────────────────────────────────────────── */
const PAINS = [
  {
    title: "흩어진 팬 접점",
    body: "SNS·공방·스트리밍으로 팬은 흩어져 있고, 한곳에 모아 매일 닿을 채널이 없습니다.",
  },
  {
    title: "막힌 수익화",
    body: "음원·굿즈·콘서트 전까지, 분명히 있는 팬심을 매출로 잇는 수단이 마땅치 않습니다.",
  },
  {
    title: "버거운 운영",
    body: "멤버가 팬 한 명 한 명을 직접 응대하기엔 시간도 손도 부족합니다.",
  },
] as const;

function Why() {
  return (
    <Section
      id="why"
      background="radial-gradient(ellipse 65% 50% at 100% 100%, rgba(0,229,255,0.10), transparent 60%), radial-gradient(ellipse 40% 30% at 0% 0%, rgba(199,112,255,0.06), transparent 60%)"
    >
      <div className="mx-auto w-full max-w-5xl">
        <div className="max-w-2xl">
          <h2 className="text-balance text-4xl font-semibold leading-tight tracking-tight text-fg sm:text-5xl">
            무대는 가끔,
            <br />
            팬과 만날 곳은 없었어요.
          </h2>
          <p className="mt-5 text-pretty text-base leading-relaxed text-fg-muted sm:text-lg">
            지하돌과 신인에게 팬덤은 곧 생존입니다. 하지만 매일 팬과 닿는 채널도,
            그 팬심을 수익으로 잇는 수단도 부족했습니다. 앙코르가 그 빈자리를
            메웁니다.
          </p>
        </div>

        <div className="mt-12 grid gap-4 sm:grid-cols-3">
          {PAINS.map((p) => (
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
      </div>
    </Section>
  );
}

/* ─────────────────────────────────────────────────────
   3. Product — 소속 아이돌이 얻는 것 (2.5D 캐릭터 + 채팅)
   ───────────────────────────────────────────────────── */
const PRODUCT_FEATURES = [
  {
    title: "매일의 1:N 채팅",
    body: "한 번 쓰면 응원하는 모든 팬에게 닿습니다. 팬은 1:1처럼 느끼고, 멤버 부담은 최소로.",
  },
  {
    title: "쌓이는 캐릭터",
    body: "후원과 함께한 시간이 2.5D 캐릭터에 쌓여, 팬을 머무르게 하는 리텐션이 됩니다.",
  },
  {
    title: "후원 = 수익",
    body: "팬의 응원이 곧 매출로. 발생한 수익은 명확한 기준으로 소속사와 나눕니다.",
  },
] as const;

function Product() {
  return (
    <Section
      id="character"
      background="radial-gradient(circle 50% at 70% 50%, rgba(255,61,161,0.14), transparent 55%), radial-gradient(circle 45% at 20% 30%, rgba(199,112,255,0.14), transparent 55%)"
    >
      <div className="mx-auto w-full max-w-6xl">
        <div className="grid items-center gap-12 lg:grid-cols-2 lg:gap-20">
          <div>
            <h2 className="text-balance text-4xl font-semibold leading-tight tracking-tight text-fg sm:text-5xl">
              매일 팬과 만나는,
              <br />
              아이돌의 디지털 분신.
            </h2>
            <p className="mt-5 text-pretty text-base leading-relaxed text-fg-muted sm:text-lg">
              2.5D 맞춤 캐릭터와 1:N 채팅으로, 소속 아이돌이 화면 너머 팬과 매일
              닿습니다. 메시지 한 줄, 작은 후원, 함께한 시간이 그대로 캐릭터에
              쌓여 팬덤을 키웁니다.
            </p>

            <dl className="mt-10 space-y-7">
              {PRODUCT_FEATURES.map((f) => (
                <div key={f.title}>
                  <dt className="text-base font-semibold text-fg">{f.title}</dt>
                  <dd className="mt-1.5 text-sm leading-relaxed text-fg-muted">
                    {f.body}
                  </dd>
                </div>
              ))}
            </dl>

            <p className="mt-10 text-xs text-fg-faint">
              일부 기능은 출시 이후 단계적으로 도입됩니다.
            </p>
          </div>

          <div className="relative flex justify-center lg:justify-end">
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
   4. HowItWorks — fan-out 구조 (멤버 부담 최소)
   ───────────────────────────────────────────────────── */
type Msg = { from: "me" | "other" | "idol"; text: string };

const HOW_IDOL: Msg[] = [
  { from: "idol", text: "오늘 무대 너무 좋았어!" },
  { from: "idol", text: "다들 잘 들어갔지?" },
];
const HOW_FAN_A: Msg[] = [
  { from: "other", text: "오늘 무대 너무 좋았어!" },
  { from: "other", text: "다들 잘 들어갔지?" },
  { from: "me", text: "너무 행복했어요" },
];
const HOW_FAN_B: Msg[] = [
  { from: "other", text: "오늘 무대 너무 좋았어!" },
  { from: "other", text: "다들 잘 들어갔지?" },
  { from: "me", text: "다음 무대는 언제예요?" },
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
            한 번 쓰면 모두에게,
            <br />
            답장은 그 아이돌에게만.
          </h2>
          <p className="mt-5 text-pretty text-base leading-relaxed text-fg-muted sm:text-lg">
            1:N fan-out 구조로 멤버의 운영 부담은 줄이고, 팬은 1:1처럼 느끼는
            거리를 유지합니다. 모든 팬이 자신만의 화면을 가집니다.
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
   5. Partners — 소속사가 얻는 것
   ───────────────────────────────────────────────────── */
const PARTNER_POINTS = [
  {
    title: "입점 0원",
    body: "초기 비용·개발 없이 합류합니다. 세팅은 저희가, 리스크 없는 시작.",
  },
  {
    title: "투명한 수익 셰어",
    body: "후원·구독 매출을 명확한 기준으로 정산하고, 데이터를 투명하게 공유합니다.",
  },
  {
    title: "멤버 부담 없는 운영",
    body: "fan-out 구조로 매일의 응대 부담을 최소화합니다. 멤버는 활동에 집중.",
  },
  {
    title: "디지털 → 오프라인 IP",
    body: "쌓인 팬덤이 첫 무대, 첫 콘서트로 이어집니다. 디지털 팬덤을 IP로 확장.",
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
            소속사 · 기획사
          </span>
          <h2 className="mt-6 text-balance text-4xl font-semibold leading-tight tracking-tight text-fg sm:text-5xl">
            소속사가 얻는 것.
          </h2>
          <p className="mt-5 text-pretty text-base leading-relaxed text-fg-muted sm:text-lg">
            앙코르는 소속사와 함께 디지털 팬덤을 만들고, 그 성장을 오프라인
            무대로 잇는 파트너입니다. 비용 부담 없이 시작해, 수익을 함께
            나눕니다.
          </p>
        </div>

        <div className="mt-12 grid gap-4 sm:grid-cols-2">
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
   6. Process — 합류 절차
   ───────────────────────────────────────────────────── */
const PROCESS = [
  {
    n: "01",
    title: "15분 데모 미팅",
    body: "먼저 듣습니다. 소속 아이돌과 수익 구조에 맞는 그림을 함께 그려요.",
  },
  {
    n: "02",
    title: "파일럿 온보딩",
    body: "한 팀으로 가볍게 시작합니다. 입점 0원, 세팅과 캐릭터 제작은 저희가.",
  },
  {
    n: "03",
    title: "런칭 & 성장",
    body: "팬덤을 키우고 수익을 나누며, 첫 무대와 그 너머까지 함께 갑니다.",
  },
] as const;

function Process() {
  return (
    <Section
      id="process"
      background="linear-gradient(135deg, rgba(0,229,255,0.08) 0%, transparent 35%, transparent 65%, rgba(199,112,255,0.10) 100%)"
    >
      <div className="mx-auto w-full max-w-5xl">
        <div className="max-w-2xl">
          <h2 className="text-balance text-4xl font-semibold leading-tight tracking-tight text-fg sm:text-5xl">
            합류는, 이렇게.
          </h2>
          <p className="mt-5 text-pretty text-base leading-relaxed text-fg-muted sm:text-lg">
            거창한 계약서 없이, 15분 대화로 시작합니다. 파일럿 한 팀으로 가볍게
            확인하고, 맞으면 함께 키워갑니다.
          </p>
        </div>

        <ol className="mt-14 space-y-6 sm:mt-16">
          {PROCESS.map((s) => (
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
            함께 만들 첫 무대,
            <br />
            <span className="text-neon">앙코르를 외쳐요.</span>
          </h2>
          <p className="mt-6 text-pretty text-lg leading-relaxed text-fg-muted">
            함께 무대를 만들 아이돌과 소속사를 찾고 있어요.
            <br />
            지금 합류하거나, 편하게 문의 주세요.
          </p>

          <WaitlistForm />

          <div className="mx-auto mt-8 w-full max-w-md">
            <div className="flex items-center gap-3 text-xs text-fg-faint">
              <span className="h-px flex-1 bg-outline-soft" />
              또는 바로 연락 주세요
              <span className="h-px flex-1 bg-outline-soft" />
            </div>
            <div className="mt-4">
              <PartnerContact />
            </div>
            <p className="mt-3 text-[11px] leading-relaxed text-fg-faint">
              받으신 메일에 회신하셔도 됩니다.
            </p>
          </div>
        </div>
      </div>

      <SiteFooter />
    </section>
  );
}
