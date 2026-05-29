/// F-001~F-006 auth — repository.
///
/// 백엔드 API (`/auth/*`) 호출 + Supabase OAuth/세션 액션.
library;

import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/api/dio_client.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/config/env.dart';
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

  /// Google 로그인 — native dialog → supabase.signInWithIdToken.
  ///
  /// iOS: GoogleService-Info.plist 자동 detect (REVERSED_CLIENT_ID URL scheme 필요)
  /// Android: google-services.json 자동 detect (SHA-1 Firebase 등록 필요)
  /// serverClientId(웹 Client ID): Android에선 필수, iOS에선 권장 (id token audience 매칭)
  ///
  /// 기존 OAuth 흐름(외부 브라우저)은 사용자가 수동 닫기 필요 + deep link 문제로
  /// 디바이스/계정마다 동작이 불안정. native는 즉시 SIGNED_IN 발화 → router 자동 전환.
  ///
  /// 취소(사용자가 dialog 닫기) 시: GoogleSignIn.signIn()이 null 반환 → silent return
  /// (호출자에서 별도 처리 없음).
  Future<void> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn(
      clientId: Env.googleIosClientId,
      serverClientId: Env.googleWebClientId,
    );
    // 매번 계정 선택 강제 — 이전 세션 잔재 제거.
    await googleSignIn.signOut();
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) return; // 사용자 취소
    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null) {
      throw const AuthException('Google idToken 발급 실패 — Client ID 설정 확인');
    }
    await supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: googleAuth.accessToken,
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
