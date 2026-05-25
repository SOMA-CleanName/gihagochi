// case_converter 단위 테스트.

import 'package:flutter_test/flutter_test.dart';
import 'package:gihagochi/core/api/case_converter.dart';

void main() {
  group('camelToSnake', () {
    test('단일 단어는 그대로', () {
      expect(camelToSnake('user'), 'user');
      expect(camelToSnake('id'), 'id');
    });

    test('camelCase → snake_case', () {
      expect(camelToSnake('userName'), 'user_name');
      expect(camelToSnake('newMessageEnabled'), 'new_message_enabled');
      expect(camelToSnake('lastUsedAt'), 'last_used_at');
    });

    test('이미 snake면 그대로 (idempotent)', () {
      expect(camelToSnake('user_name'), 'user_name');
      expect(camelToSnake('new_message_enabled'), 'new_message_enabled');
    });

    test('빈 문자열 안전', () {
      expect(camelToSnake(''), '');
    });

    test('첫 글자 대문자는 leading `_` 안 붙임', () {
      expect(camelToSnake('UserName'), 'user_name');
    });
  });

  group('snakeToCamel', () {
    test('단일 단어는 그대로', () {
      expect(snakeToCamel('user'), 'user');
    });

    test('snake_case → camelCase', () {
      expect(snakeToCamel('user_name'), 'userName');
      expect(snakeToCamel('new_message_enabled'), 'newMessageEnabled');
    });

    test('이미 camel/no underscore면 그대로 (idempotent)', () {
      expect(snakeToCamel('userName'), 'userName');
    });

    test('빈 문자열 안전', () {
      expect(snakeToCamel(''), '');
    });

    test('연속 underscore도 안전', () {
      expect(snakeToCamel('a__b'), 'aB');
    });
  });

  group('convertKeys', () {
    test('Map의 키만 변환, value는 그대로', () {
      final result = convertKeys(
        {'userName': 'kim', 'ageYears': 30},
        camelToSnake,
      );
      expect(result, {'user_name': 'kim', 'age_years': 30});
    });

    test('중첩 Map 재귀', () {
      final result = convertKeys(
        {
          'userInfo': {
            'displayName': 'Kim',
            'metaData': {'createdAt': '2026-01-01'},
          },
        },
        camelToSnake,
      );
      expect(result, {
        'user_info': {
          'display_name': 'Kim',
          'meta_data': {'created_at': '2026-01-01'},
        },
      });
    });

    test('List 안 Map 재귀', () {
      final result = convertKeys(
        [
          {'itemId': 1},
          {'itemId': 2, 'subList': [{'innerKey': 'v'}]},
        ],
        camelToSnake,
      );
      expect(result, [
        {'item_id': 1},
        {'item_id': 2, 'sub_list': [{'inner_key': 'v'}]},
      ]);
    });

    test('snake → camel 양방향', () {
      final json = {
        'fan_id': 'a',
        'idol_id': 'b',
        'is_active': true,
        'nested_obj': {'inner_field': 1},
      };
      final camel = convertKeys(json, snakeToCamel) as Map<String, dynamic>;
      expect(camel, {
        'fanId': 'a',
        'idolId': 'b',
        'isActive': true,
        'nestedObj': {'innerField': 1},
      });
    });

    test('primitive/null 그대로', () {
      expect(convertKeys(null, camelToSnake), null);
      expect(convertKeys('hello', camelToSnake), 'hello');
      expect(convertKeys(42, camelToSnake), 42);
    });
  });
}
