import type { Metadata } from "next";
import { SiteFooter } from "../_components/site-footer";
import { SiteHeader } from "../_components/site-header";

export const metadata: Metadata = {
  title: "이용약관",
  description: "앙코르 서비스 이용약관.",
};

export default function TermsPage() {
  return (
    <>
      <SiteHeader />
      <main className="mx-auto max-w-3xl px-6 pt-32 pb-24">
        <p className="text-sm text-fg-muted">최종 업데이트 — 2026년 5월 27일</p>
        <h1 className="mt-2 text-4xl font-semibold tracking-tight text-fg">
          이용약관
        </h1>
        <p className="mt-8 text-sm leading-relaxed text-fg-muted">
          본 약관 문안은 출시 전 법무 검토를 거쳐 확정 게시될 예정입니다.
          아래는 작성 중인 초안의 골격이며, 실제 효력은 정식 공지 이후
          발생합니다.
        </p>

        <section className="mt-10 space-y-8">
          <Article title="제1조 (목적)">
            본 약관은 앙코르(이하 &ldquo;회사&rdquo;)가 제공하는 서비스의
            이용과 관련하여 회사와 회원 간의 권리, 의무 및 책임사항을 규정하는
            것을 목적으로 합니다.
          </Article>
          <Article title="제2조 (용어의 정의)">
            본 약관에서 사용하는 용어의 정의는 다음과 같습니다. &ldquo;팬&rdquo;,
            &ldquo;아이돌&rdquo;, &ldquo;채팅방&rdquo;, &ldquo;응원(구독)&rdquo;
            등 핵심 용어는 정식 공지 시 명확히 규정됩니다.
          </Article>
          <Article title="제3조 (서비스 이용)">
            회원은 본 약관 및 회사의 운영정책에 따라 서비스를 이용할 수 있으며,
            아이돌 활동을 위해서는 별도의 승인 절차를 거쳐야 합니다.
          </Article>
          <Article title="제4조 (회원의 의무)">
            회원은 타인의 권리를 침해하거나 서비스의 운영을 방해하는 행위를
            하여서는 안 됩니다. 부적절한 메시지 등에 대해서는 신고 기능을 통한
            처리가 이루어집니다.
          </Article>
          <Article title="제5조 (회사의 의무 및 책임의 제한)">
            회사는 안정적인 서비스 제공을 위해 노력하며, 천재지변·시스템 장애 등
            불가항력적 사유로 인한 손해에 대해서는 책임이 제한될 수 있습니다.
          </Article>
          <Article title="제6조 (계약 해지 및 탈퇴)">
            회원은 언제든지 서비스 내 설정을 통해 탈퇴할 수 있으며, 탈퇴 후
            일정 기간 보존되는 정보 범위는 개인정보처리방침에 따릅니다.
          </Article>
        </section>

        <p className="mt-12 text-xs text-fg-faint">
          문의 — hello@encore.app
        </p>
      </main>
      <SiteFooter />
    </>
  );
}

function Article({
  title,
  children,
}: {
  title: string;
  children: React.ReactNode;
}) {
  return (
    <article>
      <h2 className="text-lg font-semibold text-fg">{title}</h2>
      <p className="mt-3 text-sm leading-relaxed text-fg-muted">{children}</p>
    </article>
  );
}
