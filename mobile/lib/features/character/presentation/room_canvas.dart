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

import 'dart:async';
import 'dart:ui' as ui;
import 'dart:ui' show lerpDouble;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../chat_message/presentation/message_input.dart';
import '../../chat_message/presentation/message_list.dart';
import '../application/character_moment_controller.dart';
import '../application/character_state_controller.dart';
import '../domain/character_action.dart';
import '../domain/character_moment.dart';
import '../game/encore_character_game.dart';
import '../game/room_world.dart';
import 'widgets/moment_card.dart';

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

  /// PR-B 시범 — flame 게임 인스턴스 보존 (매 rebuild 재생성 방지).
  /// PR-I에서 RoomCanvas 자체 정리 시 _game 라이프사이클은 새 위젯으로 이관.
  late final EncoreCharacterGame _game;

  @override
  void initState() {
    super.initState();
    // 기본 = 중간보다 약간 아래 (캐릭터 영역 더 보임).
    _expand = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      value: 0.0, // 초기 = 가장 내림 (캐릭터 영역 최대)
    );
    _game = EncoreCharacterGame(onCharacterTap: _handleCharacterTap);
  }

  /// PR-F — flame 캐릭터 탭 시 호출.
  /// 1) haptic
  /// 2) 모먼트 카드 (tap kind)
  /// 3) 백엔드 액션 트리거 (happy) — 응답 시 state 변경 → ref.listen이 character.setAction(happy)
  void _handleCharacterTap() {
    HapticFeedback.lightImpact();
    ref
        .read(characterMomentControllerProvider(widget.idolId).notifier)
        .show(CharacterMomentKind.tap);
    unawaited(
      ref
          .read(characterStateControllerProvider(widget.idolId).notifier)
          .trigger(CharacterActionType.happy),
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

    // PR-F — 백엔드 state 변경 시 flame character sprite 동기.
    // 트리거 경로: 탭 / PR-2 디버그 메뉴 / cron / AI(v2) 모두 동일하게 흘러옴.
    ref.listen(characterStateControllerProvider(widget.idolId), (prev, next) {
      next.whenData((state) {
        final world = _game.world;
        if (world is RoomWorld) {
          world.character.setAction(state.currentAction);
        }
      });
    });

    return AnimatedBuilder(
      animation: _expand,
      builder: (context, _) {
        final screenH = MediaQuery.of(context).size.height;
        final chatTop = _chatTopFor(screenH, _expand.value);
        return Stack(
          fit: StackFit.expand,
          children: [
            // Layer 1: flame GameWidget — 방 + 캐릭터 화면 풀스크린.
            // AppBar 뒤(extendBodyBehindAppBar) + 채팅창 영역까지 전체 채움.
            // 채팅창은 반투명 overlay라 GameWidget 비침. character.md v2 영역 1 명세.
            Positioned.fill(
              child: GameWidget(game: _game),
            ),
            // Layer 2: 채팅창 — top만 동적, bottom=0. 반투명 + blur.
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
            // Layer 3 (F-044): 모먼트 카드 — 채팅창 top 위에 floating, IgnorePointer.
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
        // 채팅창이 최저점 위로 올라온 경계 영역의 부드러운 전환을 위해 blur는 유지.
        filter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: DecoratedBox(
          decoration: BoxDecoration(
            // PR-N: 솔리드 — 채팅창 영역 뒤 GameWidget 안 비치게.
            // 최저점 라인 아래는 채팅바만 보이고, 위로 올라간 영역은 캐릭터 가림 (의도).
            color: AppColors.surface,
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
