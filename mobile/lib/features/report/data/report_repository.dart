/// F-033 report — 백엔드 API 호출.
///
/// camelDioProvider 사용 — camelCase ↔ snake_case 자동 변환 (PR #44).
library;

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/dio_client.dart';
import '../domain/report_models.dart';

part 'report_repository.g.dart';

@riverpod
ReportRepository reportRepository(Ref ref) {
  return ReportRepository(dio: ref.watch(camelDioProvider));
}

class ReportRepository {
  ReportRepository({required this.dio});

  final Dio dio;

  /// POST /reports — 신고 생성.
  /// 백엔드 검증: 중복(409), 자기 메시지(400), 메시지 없음(404).
  Future<ReportDetail> createReport({
    required String messageId,
    required String reason,
  }) async {
    final res = await dio.post(
      '/reports',
      data: {'messageId': messageId, 'reason': reason},
    );
    return ReportDetail.fromJson(res.data as Map<String, dynamic>);
  }
}
