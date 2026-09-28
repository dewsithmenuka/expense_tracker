import 'package:expense_tracker/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.amount', () {
    test('rejects empty input', () => expect(Validators.amount(''), isNotNull));
    test('rejects text', () => expect(Validators.amount('abc'), isNotNull));
    test('rejects zero', () => expect(Validators.amount('0'), isNotNull));
    test('rejects negatives', () => expect(Validators.amount('-5'), isNotNull));
    test('rejects huge numbers',
        () => expect(Validators.amount('99999999'), isNotNull));
    test('accepts a normal amount', () => expect(Validators.amount('45.90'), isNull));
    test('accepts a comma as decimal separator',
        () => expect(Validators.amount('12,50'), isNull));
  });

  group('Validators.balance', () {
    test('accepts zero', () => expect(Validators.balance('0'), isNull));
    test('rejects negatives', () => expect(Validators.balance('-1'), isNotNull));
    test('rejects empty input', () => expect(Validators.balance(''), isNotNull));
  });

  group('Validators.title', () {
    test('rejects empty', () => expect(Validators.title('  '), isNotNull));
    test('rejects one character', () => expect(Validators.title('a'), isNotNull));
    test('accepts a normal title', () => expect(Validators.title('Lunch'), isNull));
    test('rejects very long titles',
        () => expect(Validators.title('a' * 61), isNotNull));
  });

  group('Validators.email', () {
    test('rejects a missing @', () => expect(Validators.email('nope'), isNotNull));
    test('accepts a valid email', () => expect(Validators.email('a@b.com'), isNull));
  });

  group('Validators.password', () {
    test('rejects short passwords', () => expect(Validators.password('12345'), isNotNull));
    test('accepts 6+ characters', () => expect(Validators.password('123456'), isNull));
  });

  group('Validators.last4', () {
    test('accepts four digits', () => expect(Validators.last4('0042'), isNull));
    test('rejects three digits', () => expect(Validators.last4('123'), isNotNull));
    test('rejects letters', () => expect(Validators.last4('12a4'), isNotNull));
  });
}