'use client';

// 클라이언트 측 전역 provider — QueryClient + (추후 ThemeProvider 등)
// Server Component인 layout.tsx에서 children으로 감싼다.
import { QueryClientProvider } from '@tanstack/react-query';
import type { ReactNode } from 'react';

import { getQueryClient } from '@/lib/query-client';

export function Providers({ children }: { children: ReactNode }) {
  const queryClient = getQueryClient();

  return (
    <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
  );
}
