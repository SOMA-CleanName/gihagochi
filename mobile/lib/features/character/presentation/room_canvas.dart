/// F-039 + F-040 — 캐릭터 방 + 정적 캐릭터 + 드래그 가능한 채팅 오버레이.
///
/// chat_room의 `chatRoomCharacterSlotProvider`가 본 위젯으로 override되어
/// 채팅방 풀스크린에 표시됨.
///
/// 레이아웃:
/// - 방 배경 + 캐릭터 = 풀스크린 (Positioned.fill, 자르지 않음)
/// - 채팅창 = Positioned(top: 동적, bottom: 0) — 채팅창만 위/아래 드래그
/// - 채팅창 top 범위 = [chatTopMin (화면×0.20), chatTopMax (화면×0.60)]
/// - 채팅창은 반투명 + blur → 뒤 방 배경 은은하게 비침
library;

import 'dart:ui' as ui;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../chat_message/presentation/message_input.dart';
import '../../chat_message/presentation/message_list.dart';
import '../application/character_moment_controller.dart';
import 'widgets/character_placeholder.dart';
import 'widgets/moment_card.dart';
import 'widgets/room_background.dart';

// ── 드래그 범위 상수 (조정 가능) ──────────────────
/// 채팅창 최대로 올렸을 때 — 화면 상단에서 이 비율 위치까지 올라감.
/// 작을수록 위로 더 올라감(채팅창 커짐). AppBar 아래.
const double chatTopMinRatio = 0.20;

/// 채팅창 최대로 내렸을 때 — 화면 상단에서 이 비율 위치까지 내려감.
/// 클수록 아래로 더 내려감(채팅창 작아짐, 캐릭터 영역 커짐).
const double chatTopMaxRatio = 0.60;

/// drag end 시 snap 임계 속도 (px/s). 이 이상이면 방향대로 snap.
const double _snapVelocityThreshold = 400;

class RoomCanvas extends ConsumerWidget {
  const RoomCanvas({super.key, required this.idolId});

  final String idolId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _RoomCanvasInner(idolId: idolId);
  }
}

class _RoomCanvasInner extends ConsumerStatefulWidget {
  const _RoomCanvasInner({required this.idolId});
  final String idolId;

  @override
  ConsumerState<_RoomCanvasInner> createState() => _RoomCanvasInnerState();
}

class _RoomCanvasInnerState extends ConsumerState<_RoomCanvasInner>
    with SingleTickerProviderStateMixin {
  /// 0.0 = 채팅창 가장 아래(top=maxRatio, 캐릭터 영역 최대)
  /// 1.0 = 채팅창 가장 위(top=minRatio, 채팅 영역 최대)
  late final AnimationController _expand;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    // 기본 = 중간보다 약간 아래 (캐릭터 영역 더 보임).
    _expand = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      value: 0.0, // 초기 = 가장 내림 (캐릭터 영역 최대)
    );
  }

  @override
  void dispose() {
    _expand.dispose();
    super.dispose();
  }

  double _chatTopFor(double screenH, double v) {
    // v=1이면 minRatio (위), v=0이면 maxRatio (아래)
    return lerpDouble(
      screenH * chatTopMaxRatio,
      screenH * chatTopMinRatio,
      v,
    )!;
  }

  double get _range {
    final h = MediaQuery.of(context).size.height;
    return h * (chatTopMaxRatio - chatTopMinRatio);
  }

  void _onDragStart(DragStartDetails _) {
    _expand.stop();
    setState(() => _isDragging = true);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_range <= 0) return;
    // 핸들 위로 끄는 건 dy<0 → 채팅창 위로(value 증가)
    // 아래로 끄는 건 dy>0 → 채팅창 아래로(value 감소)
    _expand.value =
        (_expand.value - details.delta.dy / _range).clamp(0.0, 1.0);
  }

  void _onDragEnd(DragEndDetails details) {
    setState(() => _isDragging = false);
    final v = details.velocity.pixelsPerSecond.dy;
    // dy<0 (위로 swipe) → 채팅창 위로 snap (value=1)
    // dy>0 (아래로 swipe) → 채팅창 아래로 snap (value=0)
    final target = v.abs() > _snapVelocityThreshold
        ? (v < 0 ? 1.0 : 0.0)
        : (_expand.value > 0.5 ? 1.0 : 0.0);
    _expand.animateTo(target, curve: Curves.easeOutCubic);
  }

  void _onHandleTap() {
    final target = _expand.value > 0.5 ? 0.0 : 1.0;
    _expand.animateTo(target, curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final moment =
        ref.watch(characterMomentControllerProvider(widget.idolId));
    return AnimatedBuilder(
      animation: _expand,
      builder: (context, _) {
        final screenH = MediaQuery.of(context).size.height;
        final chatTop = _chatTopFor(screenH, _expand.value);
        return Stack(
          fit: StackFit.expand,
          children: [
            // Layer 1: 방 배경 — 풀스크린, 자르지 않음, 어떤 상태에서도 검정 X.
            const RoomBackground(),
            // Layer 2: 정적 캐릭터 — 채팅 카드 위 영역만 점유.
            // Column.end로 카드 상단 바로 위에 정렬 → 채팅창에 가려지지 않음.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: screenH - chatTop,
              child: SafeArea(
                bottom: false,
                child: CharacterPlaceholder(idolId: widget.idolId),
              ),
            ),
            // Layer 3: 채팅창 — top만 동적, bottom=0. 반투명 + blur.
            Positioned(
              top: chatTop,
              left: 0,
              right: 0,
              bottom: 0,
              child: _ChatCard(
                idolId: widget.idolId,
                isDragging: _isDragging,
                onDragStart: _onDragStart,
                onDragUpdate: _onDragUpdate,
                onDragEnd: _onDragEnd,
                onHandleTap: _onHandleTap,
              ),
            ),
            // Layer 4 (F-044): 모먼트 카드 — 채팅창 top 위에 floating, IgnorePointer.
            // chatTop이 변하면 함께 움직임. moment=null이면 SizedBox.shrink로 영향 0.
            Positioned(
              left: 0,
              right: 0,
              top: chatTop - _momentCardLift,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: MomentCard(moment: moment),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 채팅 카드 top 위로 카드 본체가 띄워질 거리.
const double _momentCardLift = 56;

class _ChatCard extends StatelessWidget {
  const _ChatCard({
    required this.idolId,
    required this.isDragging,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onHandleTap,
  });

  final String idolId;
  final bool isDragging;
  final GestureDragStartCallback onDragStart;
  final GestureDragUpdateCallback onDragUpdate;
  final GestureDragEndCallback onDragEnd;
  final VoidCallback onHandleTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(AppRadius.xl),
        topRight: Radius.circular(AppRadius.xl),
      ),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: DecoratedBox(
          decoration: BoxDecoration(
            // 반투명 — 뒤 방 배경이 은은하게 비치도록.
            color: AppColors.surface.withValues(alpha: 0.55),
            border: Border(
              top: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              // 진짜 드래그 핸들 — onVerticalDrag + onTap.
              _DragHandle(
                isDragging: isDragging,
                onDragStart: onDragStart,
                onDragUpdate: onDragUpdate,
                onDragEnd: onDragEnd,
                onTap: onHandleTap,
              ),
              Expanded(child: MessageList(idolId: idolId)),
              MessageInput(idolId: idolId),
            ],
          ),
        ),
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle({
    required this.isDragging,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onTap,
  });

  final bool isDragging;
  final GestureDragStartCallback onDragStart;
  final GestureDragUpdateCallback onDragUpdate;
  final GestureDragEndCallback onDragEnd;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragStart: onDragStart,
      onVerticalDragUpdate: onDragUpdate,
      onVerticalDragEnd: onDragEnd,
      onTap: onTap,
      child: SizedBox(
        height: 28,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: isDragging ? 56 : 44,
            height: 5,
            decoration: BoxDecoration(
              color: isDragging
                  ? AppColors.primary.withValues(alpha: 0.85)
                  : AppColors.onSurfaceVariant.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ),
    );
  }
}
