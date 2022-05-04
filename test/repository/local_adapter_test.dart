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
    final familia = container.familia.remoteAdapter.localAdapter.findOne(null);
    expect(familia, isNull);
  });

  test('deserialize existing (with save)', () {
    final familiaLocalAdapter = container.familia.remoteAdapter.localAdapter
        as HiveLocalAdapter<Familia>;
    final familia = Familia(surname: 'Moletto');

    // simulate "save"
    graph.getKeyForId('familia', '1098', keyIfAbsent: keyFor(familia));
    final familia2 =
        familiaLocalAdapter.deserialize({'id': '1098', 'surname': 'Moletto'});

    expect(familia2, Familia(id: '1098', surname: 'Moletto'));
    expect(familiaLocalAdapter.box!.keys, [keyFor(familia2)]);
  });

  test('deserialize many local for same remote ID', () {
    final familiaLocalAdapter = container.familia.remoteAdapter.localAdapter;
    final familia = Familia(surname: 'Moletto');
    final familia2 = Familia(surname: 'Zandiver');

    // simulate "save" for familia
    graph.getKeyForId('familia', '1298', keyIfAbsent: keyFor(familia));
    final familia1b = familiaLocalAdapter.deserialize({
      'id': '1298',
      'surname': 'Helsinki',
    });

    // simulate "save" for familia2
    graph.getKeyForId('familia', '1298', keyIfAbsent: keyFor(familia2));
    final familia2b = familiaLocalAdapter.deserialize({
      'id': '1298',
      'surname': 'Oslo',
    });

    // since obj returned with same ID
    expect(keyFor(familia1b), keyFor(familia2b));
  });

  test('local serialize', () {
    final familiaLocalAdapter = container.familia.remoteAdapter.localAdapter;
    final p1r = {Person(id: '1', name: 'Franco', age: 28)}.asHasMany;
    final h1r = House(id: '1', address: '123 Main St').asBelongsTo;

    final familia =
        Familia(id: '1', surname: 'Smith', residence: h1r, persons: p1r);

    final map = familiaLocalAdapter.serialize(familia);
    expect(map, {
      'id': '1',
      'surname': 'Smith',
      'residence': h1r,
      'persons': p1r,
    });
  });

  test('local deserialize', () {
    final familiaLocalAdapter = container.familia.remoteAdapter.localAdapter;
    final p1r = {Person(id: '1', name: 'Franco', age: 28)}.asHasMany;
    final h1r = House(id: '1', address: '123 Main St').asBelongsTo;
    final fam =
        Familia(id: '1', surname: 'Smith', persons: p1r, residence: h1r);

    final map = {
      'id': '1',
      'surname': 'Smith',
      'residence': h1r.key,
      'persons': p1r.keys,
    };

    final familia = familiaLocalAdapter.deserialize(map);
    expect(
        familia,
        Familia(
          id: '1',
          surname: 'Smith',
          residence: fam.residence,
          persons: fam.persons,
        ));
  });

  test('local deserialize with relationships', () {
    final familiaLocalAdapter = container.familia.remoteAdapter.localAdapter;
    final house = House(id: '1', address: '123 Main St');
    final person = Person(id: '1', name: 'John', age: 21);

    final obj = {
      'id': '1',
      'surname': 'Smith',
      'residence': keyFor(house),
      'persons': [keyFor(person)]
    };

    final familia = familiaLocalAdapter.deserialize(obj);

    expect(familia, Familia(id: '1', surname: 'Smith'));
    expect(familia.residence!.value!.address, '123 Main St');
    expect(familia.persons.first.age, 21);
  });

  test('hive adapter typeId', () {
    final a1 = container.familia.remoteAdapter.localAdapter
        as HiveLocalAdapter<Familia>;
    final a2 =
        container.houses.remoteAdapter.localAdapter as HiveLocalAdapter<House>;
    expect(a1.typeId, isNot(a2.typeId));
  });
}
