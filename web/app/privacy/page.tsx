import type { Metadata } from "next";
import { SiteFooter } from "../_components/site-footer";
import { SiteHeader } from "../_components/site-header";

export const metadata: Metadata = {
  title: "개인정보처리방침",
  description: "앙코르 개인정보처리방침.",
};

export default function PrivacyPage() {
  return (
    <>
      <SiteHeader />
      <main className="mx-auto max-w-3xl px-6 pt-32 pb-24">
        <p className="text-sm text-fg-muted">최종 업데이트 — 2026년 5월 27일</p>
        <h1 className="mt-2 text-4xl font-semibold tracking-tight text-fg">
          개인정보처리방침
        </h1>
        <p className="mt-8 text-sm leading-relaxed text-fg-muted">
          본 문안은 출시 전 법무 검토를 거쳐 확정 게시될 예정입니다. 아래는
          작성 중인 초안의 골격으로, 실제 효력은 정식 공지 이후 발생합니다.
        </p>

        <section className="mt-10 space-y-8">
          <Article title="1. 수집하는 개인정보 항목">
            앙코르는 서비스 제공을 위해 다음 항목을 수집합니다.
            <br />· 회원가입 시 — 이메일(소셜 로그인 시 OAuth 제공자에서 전달),
            닉네임, 프로필 이미지(선택)
            <br />· 서비스 이용 중 — 채팅 메시지, 응원 중인 아이돌 정보, 접속
            로그
            <br />· 아이돌 계정 — 활동명, 소개, 본인 확인 자료(승인 절차용)
          </Article>
          <Article title="2. 수집 및 이용 목적">
            본인 식별, 서비스 제공 및 운영, 부정 이용 방지, 신고 처리, 통계
            기반 서비스 개선 등에 사용됩니다.
          </Article>
          <Article title="3. 보유 및 이용 기간">
            회원 탈퇴 시점에 즉시 삭제하는 항목과 관계 법령에 따라 일정 기간
            보존되는 항목이 있습니다. 탈퇴 처리는 soft delete 후 30일이
            경과하면 hard delete됩니다.
          </Article>
          <Article title="4. 제3자 제공">
            법령에 근거가 있거나 회원이 사전 동의한 경우에 한하여 제3자에게
            제공됩니다. 인증·푸시·결제 등 일부 기능은 외부 처리 위탁이
            이루어지며, 위탁 현황은 별도 고지합니다.
          </Article>
          <Article title="5. 회원의 권리">
            회원은 본인의 개인정보를 조회·수정·삭제·처리 정지 요청할 수
            있습니다. 요청은 서비스 내 설정 또는 hello@encore.app으로
            가능합니다.
          </Article>
          <Article title="6. 안전성 확보 조치">
            전송 구간 암호화, 접근 권한 분리, 운영자 접근 로그 관리 등을 통해
            개인정보를 안전하게 보관합니다.
          </Article>
          <Article title="7. 개인정보 보호 책임자">
            성명·연락처는 정식 공지 시 등록됩니다. 임시 문의처 —
            hello@encore.app
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
