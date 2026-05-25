/// 백엔드 API 호출용 dio 인스턴스.
///
/// 인터셉터:
/// - request: Supabase 세션의 JWT 자동 첨부
/// - (opt-in) request body camelCase → snake_case / response 역방향
/// - response: 4xx/5xx → AppError 변환
/// - 401 시: Supabase가 자동으로 refresh (supabase_flutter 내장). 그래도 401이면 UnauthorizedError.
///
/// Provider:
/// - `dioProvider`: 기존 features용. case 변환 없음 (모델에 `@JsonKey(name: 'snake')`).
/// - `camelDioProvider`: **신규 features 권장**. case 변환 자동. 모델은 순수 camelCase.
library;

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';
import '../error/app_error.dart';
import 'case_interceptor.dart';

part 'dio_client.g.dart';

@Riverpod(keepAlive: true)
Dio dio(Ref ref) => _buildDio(withCaseInterceptor: false);

/// case_interceptor가 적용된 dio. **신규 features 권장 (opt-in)**.
///
/// 모델에서 `@JsonKey(name: 'snake_case')` 없이 camelCase 그대로 사용 가능.
/// 특정 요청만 변환 끄려면 `Options(extra: {kSkipCaseTransform: true})`.
@Riverpod(keepAlive: true)
Dio camelDio(Ref ref) => _buildDio(withCaseInterceptor: true);

Dio _buildDio({required bool withCaseInterceptor}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  dio.interceptors.add(_AuthInterceptor());
  // CaseInterceptor는 ErrorInterceptor보다 먼저 — request 변환을 응답 매핑 전에 한 번.
  if (withCaseInterceptor) {
    dio.interceptors.add(CaseInterceptor());
  }
  dio.interceptors.add(_ErrorInterceptor());

  return dio;
}

class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      options.headers['Authorization'] = 'Bearer ${session.accessToken}';
    }
    handler.next(options);
  }
}

class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final mapped = _mapToAppError(err);
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: mapped,
        type: err.type,
        response: err.response,
      ),
    );
  }

  AppError _mapToAppError(DioException err) {
    // 연결 자체 실패
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.connectionError) {
      return NetworkError(cause: err);
    }

    final status = err.response?.statusCode;
    final body = err.response?.data;
    final serverMsg = _extractMessage(body);

    return switch (status) {
      401 => UnauthorizedError(message: serverMsg, cause: err),
      403 => ForbiddenError(message: serverMsg, cause: err),
      404 => NotFoundError(message: serverMsg, cause: err),
      422 => ValidationError(message: serverMsg ?? '입력값이 올바르지 않습니다.', cause: err),
      429 => RateLimitError(cause: err),
      int s when s >= 500 => ServerError(cause: err),
      _ => UnknownError(cause: err),
    };
  }

  /// 백엔드 표준 응답 `{error: {code, message, details}}`에서 message 추출.
  String? _extractMessage(dynamic body) {
    if (body is Map<String, dynamic>) {
      final error = body['error'];
      if (error is Map<String, dynamic>) {
        final msg = error['message'];
        if (msg is String) return msg;
      }
    }
    return null;
  }
}
