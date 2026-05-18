/// 백엔드 API 호출용 dio 인스턴스.
///
/// 인터셉터:
/// - request: Supabase 세션의 JWT 자동 첨부
/// - response: 4xx/5xx → AppError 변환
/// - 401 시: Supabase가 자동으로 refresh (supabase_flutter 내장). 그래도 401이면 UnauthorizedError.
///
/// Riverpod provider로 노출. 화면에서 `ref.read(dioProvider)`.
library;

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';
import '../error/app_error.dart';

part 'dio_client.g.dart';

@Riverpod(keepAlive: true)
Dio dio(Ref ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  dio.interceptors.add(_AuthInterceptor());
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
