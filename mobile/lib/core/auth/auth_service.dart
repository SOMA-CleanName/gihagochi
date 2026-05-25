/// Supabase Auth 래퍼 + Riverpod 노출.
///
/// 핵심 provider:
/// - `authStateChangesProvider`  — 로그인 상태 스트림 (라우터 가드용)
/// - `currentUserProvider`        — 현재 Supabase User (또는 null)
/// - `authServiceProvider`        — 로그인/로그아웃 등 액션
///
/// supabase_flutter가 토큰 자동 갱신 + 세션 영속화(SharedPreferences) 자체 처리.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../error/app_error.dart';

part 'auth_service.g.dart';

/// OAuth 콜백 deep link. mobile/android/app/src/main/AndroidManifest.xml의
/// intent-filter scheme/host와 동일해야 함. Supabase Dashboard →
/// Authentication → URL Configuration → Redirect URLs에도 등록 필요.
const oauthRedirectUrl = 'com.gihagochi.gihagochi://login-callback';

/// Supabase 클라이언트 — main.dart에서 Supabase.initialize() 후 사용 가능.
@Riverpod(keepAlive: true)
SupabaseClient supabase(Ref ref) => Supabase.instance.client;

/// 로그인 상태 변화 스트림. go_router redirect에서 watch.
@Riverpod(keepAlive: true)
Stream<AuthState> authStateChanges(Ref ref) {
  return ref.watch(supabaseProvider).auth.onAuthStateChange;
}

/// 현재 인증된 User (또는 null). authStateChanges 기반 derived.
@Riverpod(keepAlive: true)
User? currentUser(Ref ref) {
  ref.watch(authStateChangesProvider); // 재계산 트리거
  return ref.watch(supabaseProvider).auth.currentUser;
}

@Riverpod(keepAlive: true)
AuthService authService(Ref ref) => AuthService(ref.watch(supabaseProvider));

class AuthService {
  AuthService(this._client);

  final SupabaseClient _client;

  /// 이메일 + 비밀번호 로그인.
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      throw UnauthorizedError(message: e.message, cause: e);
    }
  }

  /// 이메일 + 비밀번호 회원가입. (F-001 팬 가입)
  /// 확인 이메일 발송 후 사용자가 클릭해야 세션 발급됨 (Supabase 기본).
  Future<void> signUpWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.signUp(email: email, password: password);
    } on AuthException catch (e) {
      throw ValidationError(message: e.message, cause: e);
    }
  }

  /// 비밀번호 재설정 메일 발송. (F-006)
  Future<void> sendPasswordReset(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw ValidationError(message: e.message, cause: e);
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Google 소셜 로그인. Supabase Auth가 OAuth flow 전부 처리.
  /// 콜백 시 onAuthStateChange가 SIGNED_IN 이벤트를 발화.
  ///
  /// redirectTo가 없으면 Supabase가 돌아올 곳을 몰라 "사이트에 접근할 수 없음"으로 죽음.
  ///
  /// `queryParams: {'prompt': 'select_account'}` — 매번 Google 계정 선택 화면 강제.
  /// 자동 로그인(세션 복원) 흐름과는 무관 — 본 메서드는 명시적 로그인 버튼 흐름에만 호출됨.
  /// 로그아웃 후 다른 계정으로 로그인하고 싶을 때 이전 계정이 자동 선택되는 문제 방지.
  Future<void> signInWithGoogle() async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: oauthRedirectUrl,
        queryParams: const {'prompt': 'select_account'},
      );
    } on AuthException catch (e) {
      throw UnauthorizedError(message: e.message, cause: e);
    }
  }
}
