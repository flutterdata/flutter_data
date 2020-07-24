import 'package:flutter_data/flutter_data.dart';
import 'package:test/test.dart';

import '_support/person.dart';

void main() async {
  test('getType', () {
    expect(DataHelpers.getType(), isNull);
    expect(DataHelpers.getType<Person>(), 'people');
    expect(DataHelpers.getType('Family'), 'families');
    // `type` argument takes precedence
    expect(DataHelpers.getType<Person>('animal'), 'animals');
  });

  test('generateKey', () {
    expect(DataHelpers.generateKey<Person>(), isNotNull);
    expect(DataHelpers.generateKey('robots'), isNotNull);
    expect(DataHelpers.generateKey(), isNull);
  });

  test('string utils', () {
    expect('family'.capitalize(), 'Family');
    expect('people'.singularize(), 'person');
    expect('zebra'.pluralize(), 'zebras');
  });

  test('repo init args', () {
    final args = RepositoryInitializerArgs(false, true, () async {});
    expect(args.remote, false);
    expect(args.verbose, true);
    expect(args.alsoAwait, isNotNull);
    expect(RepositoryInitializerArgs(false, true, null),
        equals(RepositoryInitializerArgs(false, true, null)));
  });

  test('iterable utils', () {
    expect([1, 2, 3].safeFirst, 1);
    expect([].safeFirst, isNull);
    expect(null.safeFirst, isNull);

    expect([1, 2, 3].containsFirst(1), isTrue);
    expect([1, 2, 3].containsFirst(2), isFalse);
    expect(null.containsFirst(1), isFalse);

    expect([1, null, 3, null].filterNulls, [1, 3]);
    expect([1, 2, 3].filterNulls, [1, 2, 3]);
    // ignore: unnecessary_cast
    expect((null as Iterable).filterNulls, isNull);

    expect(null.toImmutableList(), isNull);
  });

  test('map utils', () {
    expect({'a': 1, 'b': 2} & {'b': 3}, {'a': 1, 'b': 3});
    expect({'a': 1} & {'b': 2}, {'a': 1, 'b': 2});

    expect({'a': null, 'b': 3, 'c': null}.filterNulls, {'b': 3});
  });
}
