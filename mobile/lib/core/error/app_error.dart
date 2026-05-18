/// 앱 전역 에러 계층.
///
/// dio/Supabase/기타 예외를 `AppError`로 변환해서 위로 던짐.
/// UI는 `AppError.userMessage` 표시. 분류는 `code`로.
library;

sealed class AppError implements Exception {
  const AppError({required this.code, required this.userMessage, this.cause});

  final String code;

  /// 사용자에게 그대로 보여줄 수 있는 한국어 메시지.
  final String userMessage;

  /// 원본 예외 (Sentry 캡처용).
  final Object? cause;

  @override
  String toString() => '$runtimeType(code=$code, msg=$userMessage)';
}

/// 네트워크 연결 자체 실패 (offline, DNS, timeout).
class NetworkError extends AppError {
  const NetworkError({Object? cause})
      : super(
          code: 'network',
          userMessage: '네트워크에 연결할 수 없습니다. 연결 상태를 확인해주세요.',
          cause: cause,
        );
}

/// 인증 실패. 401. 토큰 갱신 후에도 실패한 경우.
class UnauthorizedError extends AppError {
  const UnauthorizedError({String? message, Object? cause})
      : super(
          code: 'unauthorized',
          userMessage: message ?? '로그인이 필요합니다.',
          cause: cause,
        );
}

/// 권한 부족. 403.
class ForbiddenError extends AppError {
  const ForbiddenError({String? message, Object? cause})
      : super(
          code: 'forbidden',
          userMessage: message ?? '권한이 없습니다.',
          cause: cause,
        );
}

/// 리소스 없음. 404.
class NotFoundError extends AppError {
  const NotFoundError({String? message, Object? cause})
      : super(
          code: 'not_found',
          userMessage: message ?? '데이터를 찾을 수 없습니다.',
          cause: cause,
        );
}

/// 입력값 검증 실패. 422.
class ValidationError extends AppError {
  const ValidationError({required String message, Object? cause})
      : super(code: 'validation', userMessage: message, cause: cause);
}

/// rate limit. 429.
class RateLimitError extends AppError {
  const RateLimitError({Object? cause})
      : super(
          code: 'rate_limit',
          userMessage: '요청이 너무 많습니다. 잠시 후 다시 시도해주세요.',
          cause: cause,
        );
}

/// 서버 에러. 5xx. Sentry로 자동 캡처.
class ServerError extends AppError {
  const ServerError({Object? cause})
      : super(
          code: 'server',
          userMessage: '서버에서 문제가 발생했습니다. 잠시 후 다시 시도해주세요.',
          cause: cause,
        );
}

/// 분류 불가 / 예상치 못한 에러.
class UnknownError extends AppError {
  const UnknownError({Object? cause})
      : super(
          code: 'unknown',
          userMessage: '알 수 없는 오류가 발생했습니다.',
          cause: cause,
        );
}
