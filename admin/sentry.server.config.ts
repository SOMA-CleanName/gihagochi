// Sentry — 서버 사이드 (Server Components, Route Handlers, Server Actions).
import * as Sentry from '@sentry/nextjs';

if (process.env.SENTRY_DSN) {
  Sentry.init({
    dsn: process.env.SENTRY_DSN,
    environment: process.env.NEXT_PUBLIC_ENV ?? 'dev',
    tracesSampleRate: 0.1,
  });
}
