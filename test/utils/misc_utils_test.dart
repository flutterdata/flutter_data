import 'package:flutter_data/flutter_data.dart';
import 'package:test/test.dart';

import '../_support/person.dart';
import '../_support/pet.dart';

void main() async {
  test('getType', () {
    expect(() => DataHelpers.getType(), throwsA(isA<UnsupportedError>()));
    expect(DataHelpers.getType<Person>(), 'people');
    expect(DataHelpers.getType('CreditCard'), 'creditCards');
    expect(
        DataHelpers.getType('Inameclasseslikeshit'), 'inameclasseslikeshits');
    expect(DataHelpers.getType('Sheep'), 'sheep');
    expect(DataHelpers.getType('Family'), 'families');
    // `type` argument takes precedence
    expect(DataHelpers.getType<Person>('animal'), 'animals');
  });

  test('generateKey', () {
    expect(() => DataHelpers.generateKey(), throwsA(isA<UnsupportedError>()));
    expect(DataHelpers.generateKey<Person>(), isNotNull);
    expect(DataHelpers.generateKey('robots'), isNotNull);
  });

  test('uri helpers', () {
    final uri =
        'http://example.com/namespace/'.asUri / 'path/' / '../path' / '/./sub' &
            {
              'a': 1,
              'b': {'c': 3}
            };

    expect(uri.host, 'example.com');
    expect(uri.path, '/namespace/path/sub');
    expect(uri.queryParameters, {'a': '1', 'b[c]': '3'});
  });

  test('string utils', () {
    expect('Family'.decapitalize(), 'family');
    expect(''.decapitalize(), '');
    expect('family'.capitalize(), 'Family');
    expect('people'.singularize(), 'person');
    expect('zebra'.pluralize(), 'zebras');
  });

  test('repo init args', () {
    final args = RepositoryInitializerArgs(false, true);
    expect(args.remote, false);
    expect(args.verbose, true);
    expect(args, equals(RepositoryInitializerArgs(false, true)));
  });

  test('repo watch args', () {
    final args = WatchArgs<Dog>(id: 1, remote: true, params: {'a': 1});
    expect(args.id, 1);
    expect(args.remote, true);
    expect(args.params, {'a': 1});
    expect(args, equals(WatchArgs<Dog>(id: 1, remote: true, params: {'a': 1})));
  });

  test('iterable utils', () {
    expect([1, 2, 3].safeFirst, 1);
    expect([].safeFirst, isNull);

    expect([1, 2, 3].containsFirst(1), isTrue);
    expect([1, 2, 3].containsFirst(2), isFalse);

    expect([1, null, 3, null].filterNulls, [1, 3]);
    expect([1, 2, 3].filterNulls, [1, 2, 3]);
  });

  test('map utils', () {
    expect({'a': 1, 'b': 2} & {'b': 3}, {'a': 1, 'b': 3});
    expect({'a': 1} & {'b': 2}, {'a': 1, 'b': 2});

    expect({'a': null, 'b': 3, 'c': null}.filterNulls, {'b': 3});
  });
}
