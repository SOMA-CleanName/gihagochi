/// F-030 — 아이돌 프로필 편집 (`/my/edit/idol`).
///
/// 편집 가능: display_name, avatar, stage_name, bio, thumbnail.
/// 1차는 관리자 승인 없이 즉시 반영.
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

class EditIdolPage extends ConsumerStatefulWidget {
  const EditIdolPage({super.key});

  @override
  ConsumerState<EditIdolPage> createState() => _EditIdolPageState();
}

class _EditIdolPageState extends ConsumerState<EditIdolPage> {
  late final TextEditingController _displayName;
  late final TextEditingController _stageName;
  late final TextEditingController _bio;
  bool _busy = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _displayName = TextEditingController();
    _stageName = TextEditingController();
    _bio = TextEditingController();
  }

  @override
  void dispose() {
    _displayName.dispose();
    _stageName.dispose();
    _bio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncProfile = ref.watch(myProfileControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('아이돌 프로필 편집')),
      body: asyncProfile.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () =>
              ref.read(myProfileControllerProvider.notifier).refresh(),
        ),
        data: (profile) {
          if (profile.idol == null) {
            return const Center(child: Text('아이돌 프로필이 없습니다.'));
          }
          if (!_initialized) {
            _displayName.text = profile.displayName;
            _stageName.text = profile.idol!.stageName;
            _bio.text = profile.idol!.bio ?? '';
            _initialized = true;
          }
          return _buildForm(profile);
        },
      ),
    );
  }

  Widget _buildForm(MyProfile profile) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionTitle('썸네일 (대표 이미지)'),
        Center(
          child: GestureDetector(
            onTap: _busy ? null : _pickAndUploadThumbnail,
            child: _ThumbnailPreview(
              imageUrl: profile.idol?.thumbnailUrl,
              displayName: profile.idol?.stageName ?? '',
            ),
          ),
        ),
        const SizedBox(height: 24),
        _SectionTitle('프로필 사진'),
        Center(
          child: GestureDetector(
            onTap: _busy ? null : _pickAndUploadAvatar,
            child: Stack(
              children: [
                Avatar(
                  imageUrl: profile.avatarUrl,
                  fallbackText: profile.displayName,
                  size: 100,
                ),
                const Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 16,
                    child: Icon(Icons.camera_alt, size: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        AppTextField(label: '닉네임', controller: _displayName, enabled: !_busy),
        const SizedBox(height: 16),
        AppTextField(label: '활동명', controller: _stageName, enabled: !_busy),
        const SizedBox(height: 16),
        AppTextField(
          label: '소개',
          controller: _bio,
          enabled: !_busy,
          maxLines: 4,
        ),
        const SizedBox(height: 32),
        AppButton(label: '저장', isLoading: _busy, onPressed: _busy ? null : _save),
      ],
    );
  }

  Future<void> _pickAndUploadAvatar() async {
    setState(() => _busy = true);
    try {
      final bytes = await ref.read(imageUploadServiceProvider).pickAvatar();
      if (bytes == null) return;
      await ref.read(myProfileControllerProvider.notifier).uploadAvatar(bytes);
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickAndUploadThumbnail() async {
    setState(() => _busy = true);
    try {
      final bytes =
          await ref.read(imageUploadServiceProvider).pickThumbnail();
      if (bytes == null) return;
      await ref
          .read(myProfileControllerProvider.notifier)
          .uploadThumbnail(bytes);
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    final name = _displayName.text.trim();
    final stage = _stageName.text.trim();
    final bio = _bio.text.trim();
    if (name.isEmpty || stage.isEmpty) {
      _showError(Exception('닉네임과 활동명을 모두 입력해주세요.'));
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(myProfileControllerProvider.notifier).updateIdol(
            IdolProfileEdit(
              displayName: name,
              stageName: stage,
              bio: bio.isEmpty ? null : bio,
            ),
          );
      if (mounted) context.pop();
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(Object e) {
    if (!mounted) return;
    final msg = e is Exception
        ? e.toString().replaceFirst('Exception: ', '')
        : e.toString();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title, style: Theme.of(context).textTheme.labelLarge),
      );
}

class _ThumbnailPreview extends StatelessWidget {
  const _ThumbnailPreview({this.imageUrl, required this.displayName});
  final String? imageUrl;
  final String displayName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        image: imageUrl != null
            ? DecorationImage(
                image: NetworkImage(imageUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: CircleAvatar(
          radius: 16,
          child: const Icon(Icons.camera_alt, size: 16),
        ),
      ),
    );
  }
}
