/// 아이돌 채팅 메시지 → 캐릭터 액션 추론 (키워드 사전 매칭, MVP).
///
/// AI/임베딩 없이 부분 문자열 매칭으로 액션을 고른다. 프로토타입 단계 —
/// 추후 임베딩 유사도로 교체할 때 `analyzeMessageAction` 시그니처는 유지하고
/// 내부 구현(_actionKeywords)만 바꾸면 된다.
library;

import 'character_action.dart';

/// 액션별 트리거 키워드 (부분 문자열 매칭). idle은 "반응 없음"이라 사전에 없음.
const Map<CharacterActionType, List<String>> _actionKeywords = {
  CharacterActionType.sleep: [
    '졸려', '졸리', '자자', '잘자', '굿나잇', '굿밤', '피곤', '잠와', '잠이', '자러',
    '눕고', '침대', '코자', '나른', '하품', '자장', '꿈나라', '잠들', '쉬고', '자야',
  ],
  CharacterActionType.eat: [
    '배고파', '배고', '먹자', '먹고', '맛있', '간식', '냠냠', '야식', '식사', '디저트',
    '케이크', '과자', '치킨', '피자', '떡볶이', '먹방', '출출', '허기', '꿀맛', '맛집',
  ],
  CharacterActionType.sing: [
    '노래', '무대', '공연', '라이브', '콘서트', '부를게', '노래방', '멜로디', '가사', '음악',
    '마이크', '보컬', '리허설', '떼창', '앵콜', '음원', '선율', '열창', '축가', '찬양',
  ],
  CharacterActionType.happy: [
    '좋아', '행복', '최고', '사랑', '신나', '고마워', '기뻐', '즐거', '설레', '웃음',
    '짱', '축하', '럭키', '두근', '헤헤', 'ㅎㅎ', 'ㅋㅋ', '대박', '좋다', '신난',
  ],
  CharacterActionType.sad: [
    '슬퍼', '슬프', '우울', '미안', '힘들', '속상', '눈물', '울어', '울고', '외로',
    '그리워', '보고싶', '아파', '지쳐', '서운', '흑흑', 'ㅠㅠ', 'ㅜㅜ', '쓸쓸', '마음아',
  ],
};

/// 동점 시 우선순위 (앞일수록 우선) — 밝은 반응을 선호.
const List<CharacterActionType> _priority = [
  CharacterActionType.happy,
  CharacterActionType.sing,
  CharacterActionType.eat,
  CharacterActionType.sleep,
  CharacterActionType.sad,
];

/// 메시지 본문에서 최고 점수 액션 추론. 매칭 없으면 null → 반응 안 함(idle 유지).
/// 점수 = 포함된 키워드 개수. 동점은 _priority 순.
CharacterActionType? analyzeMessageAction(String content) {
  if (content.isEmpty) return null;
  final scores = <CharacterActionType, int>{};
  for (final entry in _actionKeywords.entries) {
    var score = 0;
    for (final kw in entry.value) {
      if (content.contains(kw)) score++;
    }
    if (score > 0) scores[entry.key] = score;
  }
  if (scores.isEmpty) return null;
  final maxScore = scores.values.reduce((a, b) => a > b ? a : b);
  for (final action in _priority) {
    if (scores[action] == maxScore) return action;
  }
  return null;
}
