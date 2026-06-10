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

  /// PR-G2 — 저장된 위치를 최초 1회만 복원 (이후 드래그 저장으로 인한 재호출 무시).
  bool _positionRestored = false;

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
    _game = EncoreCharacterGame(
      onCharacterTap: _handleCharacterTap,
      onPositionSaved: _handlePositionSaved,
    );
  }

  /// PR-G2 — 드래그 종료 시 위치 저장. 실패해도 로컬 위치는 유지(스낵바 X — 조용히).
  void _handlePositionSaved(double x, double y) {
    unawaited(
      ref
          .read(characterStateControllerProvider(widget.idolId).notifier)
          .savePosition(x, y),
    );
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
    // 빠른 플릭만 방향대로 끝까지 snap. 천천히 놓으면 그 위치에 그대로 멈춤(중간 정지 가능).
    if (v.abs() > _snapVelocityThreshold) {
      _expand.animateTo(v < 0 ? 1.0 : 0.0, curve: Curves.easeOutCubic);
    }
  }

  void _onHandleTap() {
    final target = _expand.value > 0.5 ? 0.0 : 1.0;
    _expand.animateTo(target, curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    // PR-F — 백엔드 state 변경 시 flame character sprite 동기.
    // 트리거 경로: 탭 / PR-2 디버그 메뉴 / cron / AI(v2) 모두 동일하게 흘러옴.
    ref.listen(characterStateControllerProvider(widget.idolId), (prev, next) {
      next.whenData((state) {
        final world = _game.world;
        if (world is RoomWorld) {
          world.character.setAction(state.currentAction);
          // PR-G2 — 저장된 위치 최초 1회 복원.
          if (!_positionRestored &&
              state.positionX != null &&
              state.positionY != null) {
            _positionRestored = true;
            world.character.setGroundPosition(
              state.positionX!,
              state.positionY!,
            );
          }
        }
      });
    });

    // 채팅 카드(MessageList 포함)는 _expand 애니메이션·드래그 중 재빌드되면 안 됨
    // (이미지 리로드·깜빡임 방지). AnimatedBuilder의 child로 고정 → 위치(top)만 갱신.
    final chatCard = _ChatCard(
      idolId: widget.idolId,
      isDragging: _isDragging,
      onDragStart: _onDragStart,
      onDragUpdate: _onDragUpdate,
      onDragEnd: _onDragEnd,
      onHandleTap: _onHandleTap,
    );

    return AnimatedBuilder(
      animation: _expand,
      child: chatCard,
      builder: (context, child) {
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
            // Layer 2: 채팅창 — top만 동적, bottom=0. child로 고정돼 재빌드 안 됨.
            Positioned(
              top: chatTop,
              left: 0,
              right: 0,
              bottom: 0,
              child: child!,
            ),
            // Layer 3 (F-044): 모먼트 카드 — 별도 Consumer로 구독해 moment 변화가
            // MessageList를 재빌드하지 않게 격리. chatTop 따라 함께 이동.
            Positioned(
              left: 0,
              right: 0,
              top: chatTop - _momentCardLift,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Consumer(
                  builder: (context, ref, _) {
                    final moment = ref.watch(
                      characterMomentControllerProvider(widget.idolId),
                    );
                    return MomentCard(moment: moment);
                  },
                ),
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
            // 극도로 투명 + blur — 뒤 방 배경/캐릭터가 거의 그대로 비침 (character.md v2 영역 1).
            color: AppColors.surface.withValues(alpha: 0.1),
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
              // 입력란 배경을 화면 바닥(네브바/홈 인디케이터 영역 포함)까지 솔리드로 확장.
              // MessageInput 내부 SafeArea(bottom)를 removePadding으로 무력화하고,
              // 동일 inset을 직접 padding으로 줘 컨텐츠는 네브바 위, 배경은 바닥까지.
              ColoredBox(
                color: AppColors.surface,
                child: MediaQuery.removePadding(
                  context: context,
                  removeBottom: true,
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.paddingOf(context).bottom,
                    ),
                    child: MessageInput(idolId: idolId),
                  ),
                ),
              ),
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
