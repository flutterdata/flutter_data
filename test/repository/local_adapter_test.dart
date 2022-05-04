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

  test('save without ID', () async {
    final p = Person(name: 'Luis');
    await container.people.save(p);
    final p2 = container.people.remoteAdapter.localAdapter.findOne(keyFor(p))!;
    expect(p, p2);
    expect(keyFor(p), keyFor(p2));
  });

  test('current and deserialized equals share same key', () async {
    final p = Person(id: '1', name: 'Luis');
    await container.people.save(p);
    final p2 = container.people.remoteAdapter.localAdapter
        .deserialize({'_id': '1', 'name': 'Luis'});
    expect(keyFor(p), keyFor(p2));
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

  test('local serialize with and without relationships', () {
    final familiaLocalAdapter = container.familia.remoteAdapter.localAdapter;
    final p1r = {Person(id: '4', name: 'Franco', age: 28)}.asHasMany;
    final h1r = House(id: '1', address: '123 Main St').asBelongsTo;

    final familia =
        Familia(id: '1', surname: 'Smith', residence: h1r, persons: p1r);

    final map = familiaLocalAdapter.serialize(familia);
    expect(map, {
      'id': '1',
      'surname': 'Smith',
      'residence': '1',
      'persons': {'4'},
    });

    // now a familia without specified relationships
    final familia2 = Familia(id: '1', surname: 'Smith');

    final map2 = familiaLocalAdapter.serialize(familia2);
    expect(map2, {
      'id': '1',
      'surname': 'Smith',
      // TODO FIX with const rels 'residence': '1', only persons as it's defaulted, residence is null!
      'persons': {'4'},
    });

    final mapWithoutRelationships =
        familiaLocalAdapter.serialize(familia, withRelationships: false);
    expect(mapWithoutRelationships, {
      'id': '1',
      'surname': 'Smith',
    });
  });

  test('local deserialize', () {
    final familiaLocalAdapter = container.familia.remoteAdapter.localAdapter;
    final p1r = {Person(id: '1', name: 'Franco', age: 28)}.asHasMany;
    final h1r = House(id: '1', address: '12345 Long Rd').asBelongsTo;
    final fam = Familia(id: '1', surname: 'Smith', persons: p1r, cottage: h1r);

    final map = {
      'id': '1',
      'surname': 'Smith',
    };

    final familia = familiaLocalAdapter.deserialize(map);
    expect(
        familia,
        Familia(
          id: '1',
          surname: 'Smith',
          cottage: fam.cottage,
          persons: fam.persons,
        ));
  });

  test('local deserialize with relationships', () {
    final familiaLocalAdapter = container.familia.remoteAdapter.localAdapter;

    final obj = {
      'id': '1',
      'surname': 'Smith',
    };

    final familia = familiaLocalAdapter.deserialize(obj);
    House(id: '1', address: '123 Main St', owner: familia.asBelongsTo);
    Person(id: '1', name: 'John', age: 21, familia: familia.asBelongsTo);

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
