/// F-XXX repository — DB/API 접근 레이어.
///
/// 두 가지 호출 패턴:
/// - Supabase 직결 (RLS 보호 — SELECT, 일부 INSERT)
/// - 백엔드 API (비즈 로직 필요 — POST/PUT, 관리자 액션)
library;

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/api/dio_client.dart';
import '../../../core/auth/auth_service.dart';
import '../domain/template_model.dart';

part 'template_repository.g.dart';

@riverpod
TemplateRepository templateRepository(Ref ref) {
  return TemplateRepository(
    supabase: ref.watch(supabaseProvider),
    dio: ref.watch(dioProvider),
  );
}

class TemplateRepository {
  TemplateRepository({required this.supabase, required this.dio});

  final SupabaseClient supabase;
  final Dio dio;

  /// Supabase 직결 — RLS 적용.
  Future<List<TemplateItem>> fetchAll() async {
    final rows = await supabase
        .from('your_table')
        .select()
        .order('created_at', ascending: false);
    return rows.map((r) => TemplateItem.fromJson(r)).toList();
  }

  /// 백엔드 API 경유 — 인증 헤더 자동 첨부.
  Future<TemplateItem> create({required String title}) async {
    final res = await dio.post('/template/items', data: {'title': title});
    return TemplateItem.fromJson(res.data as Map<String, dynamic>);
  }
}
