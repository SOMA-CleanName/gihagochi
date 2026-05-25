/// F-030 — 팬 프로필 편집 (`/my/edit/fan`).
///
/// 편집 가능: display_name, avatar.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/avatar.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../application/image_upload_service.dart';
import '../application/my_profile_controller.dart';
import '../domain/profile_models.dart';

class EditFanPage extends ConsumerStatefulWidget {
  const EditFanPage({super.key});

  @override
  ConsumerState<EditFanPage> createState() => _EditFanPageState();
}

class _EditFanPageState extends ConsumerState<EditFanPage> {
  late final TextEditingController _displayName;
  bool _busy = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _displayName = TextEditingController();
  }

  @override
  void dispose() {
    _displayName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncProfile = ref.watch(myProfileControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('프로필 편집')),
      body: asyncProfile.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () =>
              ref.read(myProfileControllerProvider.notifier).refresh(),
        ),
        data: (profile) {
          if (!_initialized) {
            _displayName.text = profile.displayName;
            _initialized = true;
          }
          return _buildForm(profile);
        },
      ),
    );
  }

  Widget _buildForm(MyProfile profile) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: GestureDetector(
              onTap: _busy ? null : _pickAndUploadAvatar,
              child: Stack(
                children: [
                  Avatar(
                    imageUrl: profile.avatarUrl,
                    fallbackText: profile.displayName,
                    size: 120,
                  ),
                  const Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 18,
                      child: Icon(Icons.camera_alt, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          AppTextField(
            label: '닉네임',
            controller: _displayName,
            enabled: !_busy,
          ),
          const SizedBox(height: 32),
          AppButton(
            label: '저장',
            isLoading: _busy,
            onPressed: _busy ? null : _save,
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadAvatar() async {
    setState(() => _busy = true);
    try {
      final bytes =
          await ref.read(imageUploadServiceProvider).pickAvatar();
      if (bytes == null) return; // 사용자 취소
      await ref.read(myProfileControllerProvider.notifier).uploadAvatar(bytes);
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    final name = _displayName.text.trim();
    if (name.isEmpty) {
      _showError(Exception('닉네임을 입력해주세요.'));
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(myProfileControllerProvider.notifier)
          .updateFan(FanProfileEdit(displayName: name));
      if (mounted) context.pop();
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(Object e) {
    if (!mounted) return;
    final msg = e is Exception ? e.toString().replaceFirst('Exception: ', '') : e.toString();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
