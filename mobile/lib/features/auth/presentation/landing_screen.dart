/// F-001/F-003 진입 화면. "Google로 시작" 버튼.
///
/// 동작: ref.read(authRepositoryProvider).signInWithGoogle() →
///       Supabase OAuth → 콜백 시 라우터가 redirect 결정.
library;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/env.dart';
import '../../../core/error/app_error.dart';
import '../../../core/widgets/app_button.dart';
import '../data/auth_repository.dart';

class LandingScreen extends ConsumerStatefulWidget {
  const LandingScreen({super.key});

  @override
  ConsumerState<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends ConsumerState<LandingScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _startGoogle() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.signInWithGoogle();
      // 로그인 성공. 가입 완료 사용자인지 확인.
      // - 200 OK → router refresh 가 `/main` 으로 처리 (그대로 둠).
      // - 404 NotFoundError 또는 401 UnauthorizedError("등록되지 않은 사용자") → 신규.
      // 백엔드 응답이 dio 인터셉터에서 DioException 으로 다시 wrap 되고 내부
      // `error` 필드에 AppError 가 담김 → on DioException + inner 타입 검사로 분기.
      try {
        await repo.fetchMe();
      } on DioException catch (e) {
        final inner = e.error;
        if (inner is NotFoundError || inner is UnauthorizedError) {
          // 신규 가입자 — signup wizard 로. router refresh 보다 먼저 push 해야
          // 디드락 회피 로직(profile_repository 의 자동 signOut) 발화 전에 도달.
          if (mounted) context.go('/auth/signup/role');
        } else {
          rethrow;
        }
      }
    } catch (e, st) {
      // raw exception을 사용자에 노출하지 말 것 — Sentry/log에만 보내고 친화 메시지로.
      debugPrint('[auth.google] signInWithOAuth 실패: $e\n$st');
      if (mounted) {
        setState(
          () => _error = '구글 로그인을 시작할 수 없어요. 잠시 후 다시 시도해주세요.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// dev 전용 빠른 로그인 — kDebugMode + Env에 자격 증명 설정된 경우만 동작.
  /// release 빌드에선 kReleaseMode 가드로 본 함수 자체가 호출 안 됨.
  Future<void> _devQuickLogin() async {
    final email = Env.devQuickLoginEmail;
    final password = Env.devQuickLoginPassword;
    if (email == null || password == null) return;

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).signInWithPassword(
            email: email,
            password: password,
          );
    } catch (e) {
      if (mounted) setState(() => _error = 'dev 로그인 실패: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Text(
                'gihagochi',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 8),
              const Text('아이돌과 팬을 잇는 1:N 채팅'),
              const Spacer(),
              AppButton(
                label: 'Google로 시작',
                onPressed: _busy ? null : _startGoogle,
                isLoading: _busy,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed:
                    _busy ? null : () => context.go('/auth/signup/role'),
                child: const Text('아이돌로 가입하기'),
              ),
              // ─── dev 전용 빠른 로그인 ───
              // kDebugMode + .env DEV_QUICK_LOGIN_EMAIL/PASSWORD 둘 다 있을 때만 노출.
              // release 빌드에선 tree-shaken.
              if (kDebugMode &&
                  Env.devQuickLoginEmail != null &&
                  Env.devQuickLoginPassword != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.amber.shade400),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.amber.shade50,
                  ),
                  child: Column(
                    children: [
                      Text(
                        '🔧 DEV ONLY',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.amber.shade900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      OutlinedButton(
                        onPressed: _busy ? null : _devQuickLogin,
                        child: Text('${Env.devQuickLoginLabel}로 빠른 로그인'),
                      ),
                    ],
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
