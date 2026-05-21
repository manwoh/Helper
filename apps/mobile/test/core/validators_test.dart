import 'package:flutter_test/flutter_test.dart';
import 'package:zhao_bang_shou/core/validators.dart';

void main() {
  group('AppValidators.requiredText', () {
    test('rejects empty text', () {
      expect(AppValidators.requiredText('', min: 2), isNotNull);
    });

    test('accepts normal text', () {
      expect(AppValidators.requiredText('需要帮忙安装桌子', min: 2), isNull);
    });

    test('rejects blocked task terms', () {
      expect(AppValidators.requiredText('这是诈骗任务', min: 2), isNotNull);
    });
  });

  group('AppValidators.optionalMoney', () {
    test('accepts empty value', () {
      expect(AppValidators.optionalMoney(''), isNull);
    });

    test('accepts positive number', () {
      expect(AppValidators.optionalMoney('120.50'), isNull);
    });

    test('rejects invalid number', () {
      expect(AppValidators.optionalMoney('-1'), isNotNull);
      expect(AppValidators.optionalMoney('abc'), isNotNull);
    });
  });
}
