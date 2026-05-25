/// F-008 ~ F-011 idol_discovery — 백엔드 API 접근 레이어.
///
/// 모든 호출은 dio 경유. Supabase 직결 안 함 (SPEC 결정).
library;

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/dio_client.dart';
import '../domain/idol_models.dart';

part 'idol_repository.g.dart';

@riverpod
IdolRepository idolRepository(Ref ref) {
  return IdolRepository(dio: ref.watch(dioProvider));
}

class IdolRepository {
  IdolRepository({required this.dio});

  final Dio dio;

  /// GET /idols — 검색 + 페이지.
  Future<IdolListPage> fetchList({
    String? query,
    int page = 1,
    int pageSize = 20,
  }) async {
    final res = await dio.get(
      '/idols',
      queryParameters: {
        if (query != null && query.isNotEmpty) 'q': query,
        'page': page,
        'page_size': pageSize,
      },
    );
    return IdolListPage.fromJson(res.data as Map<String, dynamic>);
  }

  /// GET /idols/{id} — 상세.
  Future<IdolDetail> fetchDetail(String idolId) async {
    final res = await dio.get('/idols/$idolId');
    return IdolDetail.fromJson(res.data as Map<String, dynamic>);
  }
}
