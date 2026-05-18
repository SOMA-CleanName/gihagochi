// TanStack Query 클라이언트 — 관리자 데이터 fetch + 캐시.
import { QueryClient, isServer } from '@tanstack/react-query';

function makeQueryClient() {
  return new QueryClient({
    defaultOptions: {
      queries: {
        staleTime: 60 * 1000, // 1분 — 관리자 화면은 자주 새로고침할 필요 적음
        gcTime: 5 * 60 * 1000,
        retry: 1,
        refetchOnWindowFocus: false,
      },
    },
  });
}

let browserQueryClient: QueryClient | undefined;

// 서버는 매 요청 새 인스턴스 / 브라우저는 싱글톤 (TanStack 공식 패턴)
export function getQueryClient(): QueryClient {
  if (isServer) {
    return makeQueryClient();
  }
  if (!browserQueryClient) {
    browserQueryClient = makeQueryClient();
  }
  return browserQueryClient;
}
