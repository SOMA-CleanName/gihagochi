import Link from "next/link";
import { TrackedLink } from "./tracked-link";

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
        <div className="flex items-center gap-7">
          <nav className="hidden items-center gap-7 text-sm text-fg-muted md:flex">
            <Link href="/#why" className="transition hover:text-fg">
              왜 앙코르
            </Link>
            <Link href="/#how" className="transition hover:text-fg">
              작동 방식
            </Link>
            <Link href="/#partners" className="transition hover:text-fg">
              소속사 혜택
            </Link>
            <Link href="/#process" className="transition hover:text-fg">
              합류 절차
            </Link>
          </nav>
          <TrackedLink
            href="/#finale"
            label="header_cta"
            className="rounded-full bg-primary px-4 py-2 text-sm font-semibold text-primary-on transition hover:bg-primary-hover"
          >
            데모 미팅
          </TrackedLink>
        </div>
      </div>
    </header>
  );
}
