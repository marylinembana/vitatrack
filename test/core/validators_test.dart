import 'package:flutter_test/flutter_test.dart';
import 'package:vitatrack/core/utils/validators.dart';

void main() {
  group('Validators.required', () {
    test('rejette null et vide', () {
      expect(Validators.required(null), isNotNull);
      expect(Validators.required('   '), isNotNull);
    });
    test('accepte une valeur', () {
      expect(Validators.required('ok'), isNull);
    });
    test('utilise le nom du champ dans le message', () {
      expect(Validators.required('', field: 'Le nom'), contains('Le nom'));
    });
  });

  group('Validators.email', () {
    test('valide un email correct', () {
      expect(Validators.email('user@example.com'), isNull);
      expect(Validators.email('  a.b+c@domain.co  '), isNull);
    });
    test('rejette les emails invalides', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('pas-d-arobase'), isNotNull);
      expect(Validators.email('a@b'), isNotNull);
      expect(Validators.email('@exemple.com'), isNotNull);
    });
  });

  group('Validators.password', () {
    test('minimum 6 caractères', () {
      expect(Validators.password(''), isNotNull);
      expect(Validators.password('12345'), isNotNull);
      expect(Validators.password('123456'), isNull);
    });
  });

  group('Validators.confirmPassword', () {
    test('doit correspondre au mot de passe original', () {
      expect(Validators.confirmPassword('abc', 'abc'), isNull);
      expect(Validators.confirmPassword('abc', 'xyz'), isNotNull);
    });
  });

  group('Validators.positiveNumber', () {
    test('nombre strictement positif requis', () {
      expect(Validators.positiveNumber('12.5'), isNull);
      expect(Validators.positiveNumber('0'), isNotNull);
      expect(Validators.positiveNumber('-3'), isNotNull);
      expect(Validators.positiveNumber('abc'), isNotNull);
    });
  });

  group('Validators.weight', () {
    test('plage 20-300 kg', () {
      expect(Validators.weight('70'), isNull);
      expect(Validators.weight('19'), isNotNull);
      expect(Validators.weight('301'), isNotNull);
      expect(Validators.weight('x'), isNotNull);
    });
  });

  group('Validators.age', () {
    test('plage 10-100 ans', () {
      expect(Validators.age('30'), isNull);
      expect(Validators.age('9'), isNotNull);
      expect(Validators.age('101'), isNotNull);
      expect(Validators.age('30.5'), isNotNull);
    });
  });
}
