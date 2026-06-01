"use client";

/**
 * 페이지 상단 무대 spotlight — 청록/민트 dominant + 보라/핑크 액센트.
 *
 * 지하 라이브 사진 톤 (천장에서 무대로 비추는 cool 톤 조명).
 * 하단은 [[LightSticks]]가 책임.
 *
 * pointer-events: none, mix-blend-mode: screen.
 */

export function StageLights() {
  return (
    <div
      aria-hidden
      className="pointer-events-none fixed inset-0 z-0 overflow-hidden"
      style={{ mixBlendMode: "screen" }}
    >
      {/* 위에서 비춰지는 콘 — 청록 dominant */}
      <span className="cone cone--cyan-main" />
      <span className="cone cone--mint" />
      <span className="cone cone--cyan-side" />
      <span className="cone cone--purple-accent" />
      <span className="cone cone--pink-accent" />

      <style jsx>{`
        .cone {
          position: absolute;
          border-radius: 50%;
          filter: blur(70px);
          top: -45vh;
          transform-origin: 50% 100%;
        }

        /* 중앙 청록 큰 콘 — 무대 메인 spotlight */
        .cone--cyan-main {
          width: 60vw;
          height: 90vh;
          left: 20vw;
          opacity: 0.55;
          background: radial-gradient(
            ellipse at center,
            rgba(0, 229, 255, 0.65) 0%,
            rgba(0, 229, 255, 0) 65%
          );
          animation: sweep-mid 14s ease-in-out infinite alternate;
        }
        /* 좌측 민트 */
        .cone--mint {
          width: 40vw;
          height: 85vh;
          left: 0;
          opacity: 0.42;
          background: radial-gradient(
            ellipse at center,
            rgba(110, 255, 220, 0.5) 0%,
            rgba(110, 255, 220, 0) 65%
          );
          animation: sweep-left 16s ease-in-out infinite alternate;
        }
        /* 우측 청록 */
        .cone--cyan-side {
          width: 38vw;
          height: 80vh;
          right: 0;
          opacity: 0.4;
          background: radial-gradient(
            ellipse at center,
            rgba(80, 220, 255, 0.55) 0%,
            rgba(80, 220, 255, 0) 65%
          );
          animation: sweep-right 13s ease-in-out infinite alternate;
        }
        /* 보라 액센트 (살짝) */
        .cone--purple-accent {
          width: 30vw;
          height: 70vh;
          left: 10vw;
          opacity: 0.28;
          background: radial-gradient(
            ellipse at center,
            rgba(199, 112, 255, 0.55) 0%,
            rgba(199, 112, 255, 0) 65%
          );
          animation: sweep-left 18s ease-in-out infinite alternate-reverse;
        }
        /* 핑크 액센트 (살짝) */
        .cone--pink-accent {
          width: 32vw;
          height: 72vh;
          right: 12vw;
          opacity: 0.3;
          background: radial-gradient(
            ellipse at center,
            rgba(255, 61, 161, 0.5) 0%,
            rgba(255, 61, 161, 0) 65%
          );
          animation: sweep-right 17s ease-in-out infinite alternate-reverse;
        }

        @keyframes sweep-left {
          0% {
            transform: translateX(-6vw) rotate(-7deg);
          }
          100% {
            transform: translateX(6vw) rotate(9deg);
          }
        }
        @keyframes sweep-mid {
          0% {
            transform: translateX(-3vw) rotate(3deg);
          }
          100% {
            transform: translateX(3vw) rotate(-5deg);
          }
        }
        @keyframes sweep-right {
          0% {
            transform: translateX(7vw) rotate(6deg);
          }
          100% {
            transform: translateX(-7vw) rotate(-9deg);
          }
        }

        @media (prefers-reduced-motion: reduce) {
          .cone {
            animation: none;
          }
        }
      `}</style>
    </div>
  );
}
