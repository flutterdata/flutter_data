import 'package:flutter_data/flutter_data.dart';
import 'package:test/test.dart';

import '../_support/book.dart';
import '../_support/familia.dart';
import '../_support/house.dart';
import '../_support/person.dart';
import '../_support/pet.dart';
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
    final familia = Familia(surname: 'Moletto').saveLocal();

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
    final person = Person(id: '4', name: 'Franco', age: 28);
    final house = House(id: '1', address: '123 Main St');

    final familia = Familia(
        id: '1',
        surname: 'Smith',
        residence: house.asBelongsTo,
        persons: {person}.asHasMany);

    final map = familiaLocalAdapter.serialize(familia);
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
    House(id: '1', address: '123 Main St', owner: familia.asBelongsTo)
        .saveLocal();
    Person(id: '1', name: 'John', age: 21, familia: familia.asBelongsTo)
        .saveLocal();

    expect(familia, Familia(id: '1', surname: 'Smith'));
    expect(familia.residence.value!.address, '123 Main St');
    expect(familia.persons.first.age, 21);
  });

  test('local deserialize with custom local adapter', () {
    final nodeLocalAdapter = container.nodes.remoteAdapter.localAdapter;

    final obj = {
      'id': 1,
      'name': 'node',
    };

    final node = nodeLocalAdapter.deserialize(obj);
    expect(node.name, 'nodey');
  });

  test('relationships with serialized=false', () {
    final familia = Familia(id: '1', surname: 'Test').saveLocal();
    var house = container.houses.remoteAdapter.localAdapter.deserialize({
      'id': '99',
      'address': '456 Far Trail',
      'owner': keyFor(familia),
    }).saveLocal();
    final book = container.books.remoteAdapter.localAdapter.deserialize({
      'id': 1,
      'house': keyFor(house), // since it's a localAdapter deserialization
    }).saveLocal();
    expect(house.currentLibrary!.toList(), {book});

    final map = container.houses.remoteAdapter.localAdapter.serialize(house);
    // does not container currentLibrary which was serialize=false
    expect(map.containsKey('currentLibrary'), isFalse);
    // it does contain a regular relationship like owner
    expect(map.containsKey('owner'), isTrue);
  });

  test('clear and compact graph', () async {
    final adapter =
        container.dogs.remoteAdapter.localAdapter as HiveLocalAdapter;

    // grab initial length of graph
    final graphInitialLength = adapter.graph.toMap().length;
    expect(graphInitialLength, 1); // hive adapters

    final dogs = {
      Dog(id: '91', name: 'A').saveLocal(),
      Dog(id: '92', name: 'B').saveLocal(),
      Dog(id: '93', name: 'C').saveLocal(),
      Dog(id: '94', name: 'D').saveLocal()
    };
    Dog(id: '95', name: 'E').saveLocal();

    final f1 =
        Familia(id: '1', surname: 'Smith', dogs: HasMany(dogs)).saveLocal();
    Book(id: 1, title: 'Models', ardentSupporters: HasMany()).saveLocal();

    final totalModels = 7;

    // box should now be amount of saved dogs
    expect(adapter.box!.length, 5);

    // graph should now be initial + amount of saved dogs times 2 (saves keys/IDs) + family key/id
    expect(adapter.graph.toMap().length, graphInitialLength + totalModels * 2);

    await adapter.clear();
    adapter.graph.compact(removeTypes: [adapter.internalType]);

    expect(f1.dogs, isEmpty);

    // after deleting the iterable, we should be back where we started
    expect(adapter.box!.length, 0);

    // graph should now be initial + amount of non-orphan models times 2 (saves keys/IDs)
    // basically it should be the same as before except without dog 95
    expect(adapter.graph.toMap().length,
        graphInitialLength + (totalModels - 1) * 2);

    // restore dogs
    final _ = {
      Dog(id: '91', name: 'A').saveLocal(),
      Dog(id: '92', name: 'B').saveLocal(),
      Dog(id: '93', name: 'C').saveLocal(),
      Dog(id: '94', name: 'D').saveLocal()
    };
    // relationships should be maintained
    expect(f1.dogs, hasLength(4));
  });
}
