"use client";

/**
 * 페이지 전체에 깔리는 삼색 조명 오버레이 — 지하 아이돌 어두운 네온 컨셉.
 *
 * 위/아래에서 비춰지는 보라/시안/핑크 콘 6개가 keyframe sweep으로 천천히 움직임.
 * pointer-events: none — 사용자 인터랙션 영향 없음.
 *
 * body 최상위에 fixed로 두어 모든 섹션 위/아래에서 보임. blend-mode로 어두운
 * 배경엔 색만 살짝, 밝은 영역엔 영향 미미.
 */

export function StageLights() {
  return (
    <div
      aria-hidden
      className="pointer-events-none fixed inset-0 z-0 overflow-hidden"
      style={{ mixBlendMode: "screen" }}
    >
      {/* 위에서 비춰지는 콘 3개 */}
      <span className="stage-cone stage-cone--top stage-cone--purple" />
      <span className="stage-cone stage-cone--top stage-cone--pink" />
      <span className="stage-cone stage-cone--top stage-cone--cyan" />

      {/* 아래에서 비춰지는 콘 3개 (살짝 약하게) */}
      <span className="stage-cone stage-cone--bottom stage-cone--cyan-soft" />
      <span className="stage-cone stage-cone--bottom stage-cone--pink-soft" />
      <span className="stage-cone stage-cone--bottom stage-cone--purple-soft" />

      <style jsx>{`
        .stage-cone {
          position: absolute;
          width: 38vw;
          height: 80vh;
          border-radius: 50%;
          filter: blur(60px);
          opacity: 0.55;
        }

        /* 위 콘 — 천장에 꽂힌 점에서 아래로 퍼지는 spotlight 느낌 */
        .stage-cone--top {
          top: -40vh;
          transform-origin: 50% 100%;
        }
        .stage-cone--bottom {
          bottom: -40vh;
          transform-origin: 50% 0%;
        }

        .stage-cone--purple {
          left: 5vw;
          background: radial-gradient(
            ellipse at center,
            rgba(199, 112, 255, 0.55) 0%,
            rgba(199, 112, 255, 0) 65%
          );
          animation: sweep-left 13s ease-in-out infinite alternate;
        }
        .stage-cone--pink {
          left: 32vw;
          background: radial-gradient(
            ellipse at center,
            rgba(255, 61, 161, 0.5) 0%,
            rgba(255, 61, 161, 0) 65%
          );
          animation: sweep-mid 11s ease-in-out infinite alternate;
        }
        .stage-cone--cyan {
          right: 5vw;
          background: radial-gradient(
            ellipse at center,
            rgba(0, 229, 255, 0.4) 0%,
            rgba(0, 229, 255, 0) 65%
          );
          animation: sweep-right 14s ease-in-out infinite alternate;
        }

        /* 하단 — 무대 아래 footlight 느낌. 약함. */
        .stage-cone--cyan-soft {
          left: 8vw;
          opacity: 0.32;
          background: radial-gradient(
            ellipse at center,
            rgba(0, 229, 255, 0.4) 0%,
            rgba(0, 229, 255, 0) 65%
          );
          animation: sweep-mid 15s ease-in-out infinite alternate-reverse;
        }
        .stage-cone--pink-soft {
          left: 35vw;
          opacity: 0.3;
          background: radial-gradient(
            ellipse at center,
            rgba(255, 61, 161, 0.45) 0%,
            rgba(255, 61, 161, 0) 65%
          );
          animation: sweep-left 12s ease-in-out infinite alternate-reverse;
        }
        .stage-cone--purple-soft {
          right: 8vw;
          opacity: 0.32;
          background: radial-gradient(
            ellipse at center,
            rgba(199, 112, 255, 0.45) 0%,
            rgba(199, 112, 255, 0) 65%
          );
          animation: sweep-right 13s ease-in-out infinite alternate-reverse;
        }

        @keyframes sweep-left {
          0% {
            transform: translateX(-6vw) rotate(-6deg);
          }
          100% {
            transform: translateX(6vw) rotate(8deg);
          }
        }
        @keyframes sweep-mid {
          0% {
            transform: translateX(-4vw) rotate(4deg);
          }
          100% {
            transform: translateX(4vw) rotate(-6deg);
          }
        }
        @keyframes sweep-right {
          0% {
            transform: translateX(6vw) rotate(6deg);
          }
          100% {
            transform: translateX(-6vw) rotate(-8deg);
          }
        }

        @media (prefers-reduced-motion: reduce) {
          .stage-cone {
            animation: none;
          }
        }
      `}</style>
    </div>
  );
}
