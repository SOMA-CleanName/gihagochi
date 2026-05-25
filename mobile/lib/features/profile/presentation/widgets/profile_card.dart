/// 마이페이지 상단 — avatar + display_name + (아이돌이면 stage_name) + 편집 진입.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/avatar.dart';
import '../../../auth/domain/auth_models.dart' show UserRole;
import '../../domain/profile_models.dart';

class ProfileCard extends StatelessWidget {
  const ProfileCard({super.key, required this.profile});

  final MyProfile profile;

  @override
  Widget build(BuildContext context) {
    final isIdol = profile.role == UserRole.idol;
    final editRoute = isIdol ? '/my/edit/idol' : '/my/edit/fan';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Avatar(
            imageUrl: profile.avatarUrl,
            fallbackText: profile.displayName,
            size: 72,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.displayName,
                  style: Theme.of(context).textTheme.titleLarge,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isIdol && profile.idol != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    profile.idol!.stageName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: '프로필 편집',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push(editRoute),
          ),
        ],
      ),
    );
  }
}
