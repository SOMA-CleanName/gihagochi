// Next.js 16 — Sentry server config 자동 로드.
// 런타임이 nodejs일 때만 server config 로드.
import { captureRequestError } from '@sentry/nextjs';

export async function register() {
  if (process.env.NEXT_RUNTIME === 'nodejs') {
    await import('./sentry.server.config');
  }
}

// Next.js 15+ 콜백 (Sentry 10에서 captureRequestError로 이름 변경됨).
export const onRequestError = captureRequestError;
