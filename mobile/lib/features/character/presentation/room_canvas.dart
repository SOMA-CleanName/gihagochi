/// F-039 + F-040 — 캐릭터 방 + 정적 캐릭터 + 채팅 오버레이 (PR-1).
///
/// chat_room의 `chatRoomCharacterSlotProvider`가 본 위젯으로 override되어
/// 채팅방 풀스크린에 표시됨. 채팅 카드(message_list + input)는 본 위젯이 직접
/// 끼움 — chat_room_screen은 character 슬롯에 body 전체를 위임.
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/text_styles.dart';
import '../../chat_message/presentation/message_input.dart';
import '../../chat_message/presentation/message_list.dart';
import 'widgets/character_placeholder.dart';
import 'widgets/room_background.dart';

class RoomCanvas extends ConsumerWidget {
  const RoomCanvas({super.key, required this.idolId});

  final String idolId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mq = MediaQuery.of(context);
    final keyboardInset = mq.viewInsets.bottom;
    // 채팅 카드 height — 작은 디바이스는 비율 ↑.
    final cardRatio = mq.size.height < 640 ? 0.62 : 0.55;
    final cardHeight = mq.size.height * cardRatio;

    return Stack(
      children: [
        // Layer 1: 방 배경 (폴백 = 다크 퍼플 그라데이션 + grid)
        const Positioned.fill(child: RoomBackground()),
        // Layer 2: 정적 캐릭터 (폴백 = placeholder)
        Positioned.fill(
          // 채팅 카드와 겹치지 않게 캐릭터를 위쪽 영역에 배치.
          bottom: cardHeight - AppSpacing.lg,
          child: CharacterPlaceholder(idolId: idolId),
        ),
        // Layer 3: 하단 반투명 채팅 카드
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _ChatCard(
            idolId: idolId,
            height: cardHeight + keyboardInset,
          ),
        ),
      ],
    );
  }
}

class _ChatCard extends StatelessWidget {
  const _ChatCard({required this.idolId, required this.height});

  final String idolId;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppRadius.xl),
          topRight: Radius.circular(AppRadius.xl),
        ),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.78),
              border: Border(
                top: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                // 카드 상단 capsule (시각 표시만, 액션 없음).
                Padding(
                  padding: const EdgeInsets.only(
                    top: AppSpacing.sm,
                    bottom: AppSpacing.xs,
                  ),
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color:
                          AppColors.onSurfaceVariant.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Expanded(child: MessageList(idolId: idolId)),
                MessageInput(idolId: idolId),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 카드 본문이 디자인 시스템 토큰 사용을 강조 (lint hint).
// ignore: unused_element
typedef _DesignHint = AppTextStyles;
