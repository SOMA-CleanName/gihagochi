import Link from "next/link";

export function SiteHeader() {
  return (
    <header className="fixed inset-x-0 top-0 z-50 border-b border-outline-soft bg-bg/70 backdrop-blur-xl">
      <div className="mx-auto flex h-14 max-w-6xl items-center justify-between px-6">
        <Link
          href="/"
          className="text-base font-semibold tracking-tight text-fg"
        >
          앙코르
        </Link>
        <nav className="hidden items-center gap-7 text-sm text-fg-muted md:flex">
          <Link href="/#ways" className="transition hover:text-fg">
            함께하는 방식
          </Link>
          <Link href="/#character" className="transition hover:text-fg">
            캐릭터
          </Link>
          <Link href="/#journey" className="transition hover:text-fg">
            여정
          </Link>
          <Link href="/#how" className="transition hover:text-fg">
            구조
          </Link>
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
