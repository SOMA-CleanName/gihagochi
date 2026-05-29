/// F-001~F-006 auth — repository.
///
/// 백엔드 API (`/auth/*`) 호출 + Supabase OAuth/세션 액션.
library;

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/api/dio_client.dart';
import '../../../core/auth/auth_service.dart';
import '../domain/auth_models.dart';

part 'auth_repository.g.dart';

@riverpod
AuthRepository authRepository(Ref ref) {
  return AuthRepository(
    supabase: ref.watch(supabaseProvider),
    dio: ref.watch(dioProvider),
  );
}

class AuthRepository {
  AuthRepository({required this.supabase, required this.dio});

  final SupabaseClient supabase;
  final Dio dio;

  // ── Supabase OAuth ─────────────────────────

  /// Google 소셜 OAuth 시작. Supabase가 시스템 브라우저로 Google 로그인 → 동의 →
  /// `oauthRedirectUrl`(deep link)로 앱 복귀 → onAuthStateChange가 SIGNED_IN 발화 →
  /// 라우터의 refresh 리스너가 redirect 결정.
  ///
  /// redirectTo 없으면 Supabase가 콜백 후 갈 곳을 몰라 브라우저에 "사이트에 접근할 수 없음"으로 죽음.
  ///
  /// `queryParams: {'prompt': 'select_account'}` — 매번 Google 계정 선택 화면 강제.
  /// 이전에 동의한 계정이 자동 SSO로 잡혀버리는 문제 방지.
  Future<void> signInWithGoogle() async {
    await supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: oauthRedirectUrl,
      queryParams: const {'prompt': 'select_account'},
    );
  }

  /// 이메일 + 비밀번호 로그인 — dev 전용 빠른 로그인용.
  /// production 플로우에서 호출 X. landing 화면의 dev 버튼이 kDebugMode 가드로만 호출.
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    await supabase.auth.signInWithPassword(email: email, password: password);
  }

  // ── 백엔드 API ─────────────────────────────

  /// POST /auth/signup — 프로필 + (선택)아이돌 신청 + 약관 동의 트랜잭션 생성.
  ///
  /// 호출 시점: OAuth 콜백 후, profile 없을 때.
  /// 409면 호출자가 "이미 가입됨"으로 해석하고 fetchMe()로 fallback.
  Future<SignupResponse> signup(SignupRequest req) async {
    final res = await dio.post('/auth/signup', data: req.toJson());
    return SignupResponse.fromJson(res.data as Map<String, dynamic>);
  }

  /// GET /auth/me — 현재 사용자 프로필 + 최신 아이돌 신청 상태.
  /// 404면 호출자가 "프로필 미생성"으로 해석하고 signup 흐름으로 유도.
  Future<MeResponse> fetchMe() async {
    final res = await dio.get('/auth/me');
    return MeResponse.fromJson(res.data as Map<String, dynamic>);
  }

  /// POST /auth/logout — 서버측 로깅용 (실제 토큰 무효화는 supabase.signOut).
  Future<void> logoutBackend() async {
    await dio.post('/auth/logout');
  }

  /// GET /auth/terms/current — 현재 활성 약관 version (비인증 OK).
  Future<TermsCurrent> fetchCurrentTerms() async {
    final res = await dio.get('/auth/terms/current');
    return TermsCurrent.fromJson(res.data as Map<String, dynamic>);
  }

  /// POST /auth/terms/reagree — 약관 재동의. 204 No Content.
  Future<void> reagree(ReagreeRequest req) async {
    await dio.post('/auth/terms/reagree', data: req.toJson());
  }

  // ── Supabase signOut + 백엔드 로그아웃 묶음 ────────────────

  /// 로그아웃. 백엔드 호출 실패해도 로컬 세션은 강제 클리어.
  Future<void> signOut() async {
    try {
      await logoutBackend();
    } catch (_) {
      // 백엔드 도달 실패해도 진행 — 로컬 세션 클리어가 핵심.
    }
    await supabase.auth.signOut();
  }
}
