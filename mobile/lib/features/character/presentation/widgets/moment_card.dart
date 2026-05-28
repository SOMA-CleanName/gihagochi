/// F-044 — 캐릭터 모먼트 카드.
///
/// 채팅 카드 top 바로 위에 floating. slide-in/out 애니메이션.
/// 5s autoHide는 [CharacterMomentController]가 담당 — 본 위젯은 상태 변화만 반응.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/radius.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../domain/character_moment.dart';

class MomentCard extends StatefulWidget {
  const MomentCard({super.key, required this.moment});

  /// null이면 hide (slide-out 애니메이션 후 SizedBox.shrink).
  final CharacterMoment? moment;

  @override
  State<MomentCard> createState() => _MomentCardState();
}

class _MomentCardState extends State<MomentCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  CharacterMoment? _lastShown;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _opacity = CurvedAnimation(parent: _enter, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _enter, curve: Curves.easeOutCubic));

    if (widget.moment != null) {
      _lastShown = widget.moment;
      _enter.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant MomentCard old) {
    super.didUpdateWidget(old);
    final cur = widget.moment;
    if (cur != null && cur != old.moment) {
      // 새 moment 등장 — 또는 같은 kind 재시작.
      _lastShown = cur;
      _enter.forward(from: 0);
    } else if (cur == null && old.moment != null) {
      // dismiss 요청 — slide-out.
      _enter.reverse();
    }
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = _lastShown;
    if (m == null) return const SizedBox.shrink();

    return IgnorePointer(
      // 카드 자체는 시각만 — pointer event 통과 (메시지 입력/스크롤 영향 X).
      child: FadeTransition(
        opacity: _opacity,
        child: SlideTransition(
          position: _slide,
          child: _CardBody(moment: m),
        ),
      ),
    );
  }
}

class _CardBody extends StatelessWidget {
  const _CardBody({required this.moment});

  final CharacterMoment moment;

  @override
  Widget build(BuildContext context) {
    final color = _accentFor(moment.kind);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(
          color: color.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 24,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_iconFor(moment.kind), size: 18, color: color),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              moment.displayMessage,
              style: AppTextStyles.labelMd.copyWith(
                color: AppColors.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  static IconData _iconFor(CharacterMomentKind kind) {
    switch (kind) {
      case CharacterMomentKind.gift:
        return Icons.card_giftcard;
      case CharacterMomentKind.tap:
        return Icons.auto_awesome;
      case CharacterMomentKind.feed:
        return Icons.restaurant;
      case CharacterMomentKind.praise:
        return Icons.favorite;
    }
  }

  static Color _accentFor(CharacterMomentKind kind) {
    switch (kind) {
      case CharacterMomentKind.gift:
        return AppColors.tertiary;
      case CharacterMomentKind.tap:
        return AppColors.secondary;
      case CharacterMomentKind.feed:
        return AppColors.primary;
      case CharacterMomentKind.praise:
        return AppColors.primary;
    }
  }
}
