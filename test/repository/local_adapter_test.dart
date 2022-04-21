import 'package:flutter_data/flutter_data.dart';
import 'package:test/test.dart';

import '../_support/familia.dart';
import '../_support/house.dart';
import '../_support/person.dart';
import '../_support/setup.dart';

void main() async {
  setUp(setUpFn);
  tearDown(tearDownFn);

  test('findOne with null key', () {
    final familia = familiaRemoteAdapter.localAdapter.findOne(null);
    expect(familia, isNull);
  });

  test('deserialize existing (with save)', () {
    final familia = Familia(surname: 'Moletto').init(container.read);

    // simulate "save"
    graph.getKeyForId('familia', '1098', keyIfAbsent: keyFor(familia));
    final familia2 = familiaRemoteAdapter.localAdapter
        .deserialize({'id': '1098', 'surname': 'Moletto'}).init(container.read);

    expect(familia2, Familia(id: '1098', surname: 'Moletto'));
    expect(
        (familiaRemoteAdapter.localAdapter as HiveLocalAdapter<Familia>)
            .box!
            .keys,
        [keyFor(familia2)]);
  });

  test('deserialize many local for same remote ID', () {
    final familia = Familia(surname: 'Moletto').init(container.read);
    final familia2 = Familia(surname: 'Zandiver').init(container.read);

    // simulate "save" for familia
    graph.getKeyForId('familia', '1298', keyIfAbsent: keyFor(familia));
    final familia1b = familiaRemoteAdapter.localAdapter.deserialize({
      'id': '1298',
      'surname': 'Helsinki',
    }).init(container.read);

    // simulate "save" for familia2
    graph.getKeyForId('familia', '1298', keyIfAbsent: keyFor(familia2));
    final familia2b = familiaRemoteAdapter.localAdapter.deserialize({
      'id': '1298',
      'surname': 'Oslo',
    }).init(container.read);

    // since obj returned with same ID
    expect(keyFor(familia1b), keyFor(familia2b));
  });

  test('local serialize', () {
    final p1r = {Person(id: '1', name: 'Franco', age: 28)}.asHasMany;
    final h1r = House(id: '1', address: '123 Main St').asBelongsTo;

    final familia =
        Familia(id: '1', surname: 'Smith', residence: h1r, persons: p1r);

    final map = familiaRemoteAdapter.localAdapter.serialize(familia);
    expect(map, {
      'id': '1',
      'surname': 'Smith',
      'residence': h1r,
      'persons': p1r,
    });
  });

  test('local deserialize', () {
    final p1r = {Person(id: '1', name: 'Franco', age: 28)}.asHasMany;
    final h1r = House(id: '1', address: '123 Main St').asBelongsTo;

    final map = {
      'id': '1',
      'surname': 'Smith',
      'residence': h1r.key,
      'persons': p1r.keys,
    };

    final familia = familiaRemoteAdapter.localAdapter.deserialize(map);
    expect(
        familia,
        Familia(
          id: '1',
          surname: 'Smith',
          residence: h1r,
          persons: p1r,
        ));
  });

  test('local deserialize with relationships', () {
    final house = House(id: '1', address: '123 Main St').init(container.read);
    final person = Person(id: '1', name: 'John', age: 21).init(container.read);

    final obj = {
      'id': '1',
      'surname': 'Smith',
      'residence': keyFor(house),
      'persons': [keyFor(person)]
    };

    final familia =
        familiaRemoteAdapter.localAdapter.deserialize(obj).init(container.read);

    expect(familia, Familia(id: '1', surname: 'Smith'));
    expect(familia.residence!.value!.address, '123 Main St');
    expect(familia.persons.first.age, 21);
  });

  test('hive adapter typeId', () {
    final a1 = familiaRemoteAdapter.localAdapter as HiveLocalAdapter<Familia>;
    final a1b = familiaRemoteAdapter.localAdapter as HiveLocalAdapter<Familia>;
    final a2 = houseRemoteAdapter.localAdapter as HiveLocalAdapter<House>;
    expect(a1.typeId, equals(a1b.typeId));
    expect(a1.typeId, isNot(a2.typeId));
  });
}
