import 'package:bizops/core/error/failures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StorageFailure', () {
    test('constructs with message', () {
      const failure = StorageFailure('disk error');
      expect(failure, isA<StorageFailure>());
    });

    test('message is accessible', () {
      const failure = StorageFailure('disk error');
      expect(failure.message, 'disk error');
    });

    test('is a Failure', () {
      const failure = StorageFailure('disk error');
      expect(failure, isA<Failure>());
    });

    test('is not equal to different variant with same message', () {
      const a = StorageFailure('disk error');
      const b = NotFoundFailure('disk error');
      expect(a, isNot(same(b)));
      expect(a.runtimeType, isNot(b.runtimeType));
    });
  });

  group('NotFoundFailure', () {
    test('constructs with message', () {
      const failure = NotFoundFailure('record missing');
      expect(failure, isA<NotFoundFailure>());
    });

    test('message is accessible', () {
      const failure = NotFoundFailure('record missing');
      expect(failure.message, 'record missing');
    });

    test('is a Failure', () {
      const failure = NotFoundFailure('record missing');
      expect(failure, isA<Failure>());
    });

    test('is not equal to different variant', () {
      const a = NotFoundFailure('record missing');
      const b = ValidationFailure('record missing');
      expect(a.runtimeType, isNot(b.runtimeType));
    });
  });

  group('ValidationFailure', () {
    test('constructs with message', () {
      const failure = ValidationFailure('invalid input');
      expect(failure, isA<ValidationFailure>());
    });

    test('message is accessible', () {
      const failure = ValidationFailure('invalid input');
      expect(failure.message, 'invalid input');
    });

    test('is a Failure', () {
      const failure = ValidationFailure('invalid input');
      expect(failure, isA<Failure>());
    });

    test('is not equal to different variant', () {
      const a = ValidationFailure('invalid input');
      const b = UnexpectedFailure('invalid input');
      expect(a.runtimeType, isNot(b.runtimeType));
    });
  });

  group('UnexpectedFailure', () {
    test('constructs with message', () {
      const failure = UnexpectedFailure('unknown error');
      expect(failure, isA<UnexpectedFailure>());
    });

    test('message is accessible', () {
      const failure = UnexpectedFailure('unknown error');
      expect(failure.message, 'unknown error');
    });

    test('is a Failure', () {
      const failure = UnexpectedFailure('unknown error');
      expect(failure, isA<Failure>());
    });

    test('is not equal to different variant', () {
      const a = UnexpectedFailure('unknown error');
      const b = StorageFailure('unknown error');
      expect(a.runtimeType, isNot(b.runtimeType));
    });
  });

  test('all four variants are distinct runtime types', () {
    const storage = StorageFailure('x');
    const notFound = NotFoundFailure('x');
    const validation = ValidationFailure('x');
    const unexpected = UnexpectedFailure('x');

    expect(storage.runtimeType, isNot(notFound.runtimeType));
    expect(storage.runtimeType, isNot(validation.runtimeType));
    expect(storage.runtimeType, isNot(unexpected.runtimeType));
    expect(notFound.runtimeType, isNot(validation.runtimeType));
    expect(notFound.runtimeType, isNot(unexpected.runtimeType));
    expect(validation.runtimeType, isNot(unexpected.runtimeType));
  });

  test('sealed class exhaustive switch compiles and covers all variants', () {
    // This test verifies that the sealed class switch is exhaustive at compile time.
    // If a variant is added without updating this switch, the analyzer will flag it.
    Failure failure = const StorageFailure('test');
    final label = switch (failure) {
      StorageFailure() => 'storage',
      NotFoundFailure() => 'notFound',
      ValidationFailure() => 'validation',
      UnexpectedFailure() => 'unexpected',
    };
    expect(label, 'storage');
  });
}
