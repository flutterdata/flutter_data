import 'package:flutter_data/flutter_data.dart';
import 'package:test/test.dart';

import '../_support/familia.dart';
import '../_support/fruit.dart';
import '../_support/house.dart';
import '../_support/person.dart';
import '../_support/setup.dart';

void main() async {
  setUp(setUpFn);
  tearDown(tearDownFn);

  test('local adapter roundtrip 1', () async {
    final p = Person(name: 'Luis');
    await container.people.save(p);
    final pb = container.people.remoteAdapter.localAdapter.findOne(keyFor(p))!;
    expect(p, pb);
    expect(keyFor(p), keyFor(pb));

    final p2 = Person(id: '2', name: 'Martin');
    await container.people.save(p2);
    final p2b =
        container.people.remoteAdapter.localAdapter.findOne(keyFor(p2))!;
    expect(p2, p2b);
    expect(keyFor(p2), keyFor(p2b));
  });

  test('local adapter roundtrip 2', () async {
    final fruit = Fruit(
      id: 34,
      boolean: true,
      date: DateTime.now(),
      integer: 1,
      listMaybeBoolean: [false, null],
      listMaybeDate: [DateTime.now(), null],
      listMaybeInteger: [6, null],
      listMaybeString: ['a', null],
      string: 'a',
      maybeBoolean: false,
      maybeDate: null,
      maybeListMaybeDate: [DateTime.now()],
      maybeInteger: 2,
      bigInt: BigInt.from(2),
      classification: Classification.closed,
      delimitedString: {'a', 'b'},
      duration: Duration(seconds: 28),
      iterable: ['1', '2', '3'],
      map: {'a': 1, 'b': 2},
      boolMap: {'a': true, 'b': false, 'c': false},
      set: {'a', 'b', 'z'},
      uri: Uri.parse('https://flutterdata.dev'),
    )..classification = Classification.closed;

    await container.fruits.save(fruit);
    print(keyFor(fruit));
    final fruit2 =
        container.fruits.remoteAdapter.localAdapter.findOne(keyFor(fruit));
    expect(fruit, fruit2);
  });

  test('current and deserialized equals share same key', () async {
    final p = Person(id: '1', name: 'Luis');
    await container.people.save(p);
    final p2 = container.people.remoteAdapter.localAdapter
        .deserialize({'_id': '1', 'name': 'Luis'});
    expect(keyFor(p), keyFor(p2));
  });

  test('deserialize existing (with save)', () {
    final familiaLocalAdapter = container.familia.remoteAdapter.localAdapter;
    final familia2 =
        familiaLocalAdapter.deserialize({'id': '1098', 'surname': 'Moletto'});
    expect(familia2, Familia(id: '1098', surname: 'Moletto'));
  });

  test('deserialize many local for same remote ID', () {
    final familiaLocalAdapter = container.familia.remoteAdapter.localAdapter;

    final familia1b = familiaLocalAdapter.deserialize({
      'id': '1298',
      'surname': 'Helsinki',
    });

    final familia2b = familiaLocalAdapter.deserialize({
      'id': '1298',
      'surname': 'Oslo',
    });

    // since obj returned with same ID
    expect(keyFor(familia1b), keyFor(familia2b));
  });

  test('local serialize with and without relationships', () {
    final familiaLocalAdapter = container.familia.remoteAdapter.localAdapter;
    final person = Person(id: '4', name: 'Franco', age: 28).saveLocal();

    final house = House(id: '1', address: '123 Main St').saveLocal();

    print('***');

    final familia = Familia(
        id: '1',
        surname: 'Smith',
        residence: house.asBelongsTo,
        persons: {person}.asHasMany);

    final map = familiaLocalAdapter.serialize(familia);
    print(map);

    expect(map, {
      'id': '1',
      'surname': 'Smith',
      'residence': keyFor(house),
      'persons': {keyFor(person)},
    });

    // now a familia without specified relationships,
    // still serializes the defaults
    final familia2 = Familia(id: '1', surname: 'Smith');

    final map2 = familiaLocalAdapter.serialize(familia2);
    expect(map2, {
      'id': '1',
      'surname': 'Smith',
      'residence': keyFor(house),
      'persons': {keyFor(person)},
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
    expect(familia.residence.value!.address, '123 Main St');
    expect(familia.persons.first.age, 21);
  });

  // test('hive adapter typeId', () {
  //   final a1 = container.familia.remoteAdapter.localAdapter;
  //       // as HiveLocalAdapter<Familia>;
  //   final a2 =
  //       container.houses.remoteAdapter.localAdapter; // as HiveLocalAdapter<House>;
  //   expect(a1.typeId, isNot(a2.typeId));
  // });

  test('relationships with serialized=false', () {
    final familia = Familia(id: '1', surname: 'Test');
    var house = container.houses.remoteAdapter.localAdapter.deserialize({
      'id': '99',
      'address': '456 Far Trail',
      'owner': keyFor(familia),
    }).saveLocal();
    final book = container.books.remoteAdapter.localAdapter.deserialize({
      'id': 1,
      'house': keyFor(house), // since it's a localAdapter deserialization
    });
    expect(house.currentLibrary!.toList(), {book});

    final map = container.houses.remoteAdapter.localAdapter.serialize(house);
    // does not container currentLibrary which was serialize=false
    expect(map.containsKey('currentLibrary'), isFalse);
    // it does contain a regular relationship like owner
    expect(map.containsKey('owner'), isTrue);
  });
}
