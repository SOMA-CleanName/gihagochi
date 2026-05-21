/// F-001/F-003 진입 화면. "Google로 시작" 버튼.
///
/// 동작: ref.read(authRepositoryProvider).signInWithGoogle() →
///       Supabase OAuth → 콜백 시 라우터가 redirect 결정.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
      await ref.read(authRepositoryProvider).signInWithGoogle();
      // OAuth 콜백 후 onAuthStateChange → 라우터가 다음 화면 결정.
    } catch (e) {
      if (mounted) setState(() => _error = '로그인 실패: $e');
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
