import 'package:flutter_data/flutter_data.dart';
import 'package:test/test.dart';

import '_support/person.dart';
import '_support/setup.dart';

void main() async {
  setUp(setUpFn);

  test('getType & generateKey', () {
    expect(DataHelpers.getType(), isNull);
    expect(DataHelpers.getType<Person>(), 'people');
    expect(DataHelpers.getType('Family'), 'families');
    // `type` argument takes precedence
    expect(DataHelpers.getType<Person>('animal'), 'animals');
    expect(DataHelpers.generateKey(), isNull);
  });
}
