import 'package:flutter_data/flutter_data.dart';
import 'package:test/test.dart';

import '../_support/book.dart';
import '../_support/familia.dart';
import '../_support/house.dart';
import '../_support/node.dart';
import '../_support/person.dart';
import '../_support/pet.dart';
import '../_support/setup.dart';

void main() async {
  setUpAll(setUpIsar);
  tearDownAll(tearDownIsar);
  setUp(setUpFn);
  tearDown(tearDownFn);

  test('save', () async {
    final familia = Familia(id: '55', surname: 'Kelley');
    expect(await container.familia.findOne('55', remote: false), isNull);

    final person =
        Person(id: '1', name: 'John', age: 27, familia: familia.asBelongsTo);
    await person.save();

    // (1) it wires up the relationship
    expect(person.familia.key, graph.getKeyForId('familia', '55'));

    // (2) it saves the model locally
    expect(person, await container.people.findOne(person.id!, remote: false));
  });

  test('on model init', () async {
    Node(id: 3, name: 'child');
    // child is saved on model init, so it should find it
    final result = await container.nodes.findOne(3);
    expect(result!.id, 3);
  });

  test('withKeyOf', () {
    final familias = [
      Familia(id: '1', surname: 'Tester 1').saveLocal(),
      Familia(id: '2', surname: 'Tester 2').saveLocal(),
      Familia(id: '3', surname: 'Tester 3').saveLocal(),
      Familia(id: '4', surname: 'Tester 4').saveLocal(),
      Familia(id: '5', surname: 'Tester 5').saveLocal()
    ];

    final pairs = [
      // source without ID + destination with ID
      [
        Person(name: 'Peter', familia: familias[0].asBelongsTo),
        Person(id: '1', name: 'Peter Updated', familia: familias[0].asBelongsTo)
      ],
      // source without ID + destination without ID
      [
        Person(name: 'Sonya', familia: familias[1].asBelongsTo),
        Person(name: 'Sonya Updated', familia: familias[1].asBelongsTo)
      ],
      // source with ID + destination with same ID
      [
        Person(id: '2', name: 'Mark', familia: familias[2].asBelongsTo),
        Person(id: '2', name: 'Mark Updated', familia: familias[2].asBelongsTo)
      ],
      // source with ID + destination with different ID
      [
        Person(id: '3', name: 'Daniel', familia: familias[3].asBelongsTo),
        Person(
            id: '4', name: 'Daniel Updated', familia: familias[3].asBelongsTo)
      ],
      // source with ID + destination without ID
      [
        Person(id: '5', name: 'Peter', familia: familias[4].asBelongsTo),
        Person(name: 'Peter Updated', familia: familias[4].asBelongsTo)
      ],
    ];

    for (final pair in pairs) {
      final index = pairs.indexOf(pair);
      // we receive an update from the server,
      // gets initialized with a new key destination
      final source = pair.first;
      final destination = pair.last;

      final destKeyBefore = keyFor(destination);

      if (keyFor(source) != keyFor(destination)) {
        expect(graph.getNode(destKeyBefore), isNotNull);
      }

      destination.withKeyOf(source);

      // now both objects have the same key
      expect(keyFor(source), keyFor(destination));

      if (destination.id != null) {
        // now the source key is associated to id=destination.id
        expect(graph.getKeyForId('people', destination.id), keyFor(source));
      }
      expect(destination.familia.value, familias[index]);

      if (keyFor(source) != keyFor(destination)) {
        expect(graph.getNode(destKeyBefore), isNull);
      }
    }

    // test freezed copyWith with different IDs
    final house = House(address: '123 Main St').saveLocal();
    final b1 =
        Book(id: 1, house: house.asBelongsTo, ardentSupporters: HasMany());
    final b2 = b1.copyWith(id: 2);

    b2.withKeyOf(b1);

    expect(keyFor(b1), keyFor(b2));
    expect(b2.house?.value, house);

    // test library using DataModelMixin (that can be uninitialized)
    final sourceLibrary = Library(id: 1, name: 'one', books: HasMany());
    final destinationLibrary = Library(id: 2, name: 'two', books: HasMany());

    expect(() => destinationLibrary.withKeyOf(sourceLibrary), throwsException);

    final initializedSourceLibrary = sourceLibrary.init();
    destinationLibrary.withKeyOf(initializedSourceLibrary);
    expect(DataModelMixin.keyFor(initializedSourceLibrary),
        DataModelMixin.keyFor(destinationLibrary));
  });

  test('findOne (remote and local reload)', () async {
    var familia = await Familia(id: '1', surname: 'Perez').save(remote: true);
    familia = Familia(id: '1', surname: 'Perez Gomez');

    container.read(responseProvider.notifier).state = TestResponse.json('''
        { "id": "1", "surname": "Perez" }
      ''');

    familia = (await familia.reload())!;
    expect(familia, Familia(id: '1', surname: 'Perez'));
    expect(await container.familia.findOne('1'),
        Familia(id: '1', surname: 'Perez'));

    Familia(id: '1', surname: 'Perez Lopez').saveLocal();
    expect(familia.surname, isNot('Perez Lopez'));
    familia = familia.reloadLocal()!;
    expect(familia.surname, equals('Perez Lopez'));
  });

  test('delete model with and without ID', () async {
    final adapter = container.people.remoteAdapter.localAdapter;
    // create a person WITH ID and assert it's there
    final person = Person(id: '21103', name: 'John', age: 54).saveLocal();
    expect(adapter.findAll(), hasLength(1));

    // delete that person and assert it's not there
    await person.delete();
    expect(adapter.findAll(), hasLength(0));

    // create a person WITHOUT ID and assert it's there
    final person2 = Person(name: 'Peter', age: 101).saveLocal();
    expect(adapter.findAll(), hasLength(1));

    // delete that person (this time via `deleteLocal`) and assert it's not there
    person2.deleteLocal();
    expect(adapter.findAll(), hasLength(0));
  });

  test('should reuse key', () {
    // id-less person
    final p1 = Person(name: 'Frank', age: 20).saveLocal();
    expect(
        (container.people.remoteAdapter.localAdapter
                as HiveLocalAdapter<Person>)
            .box!
            .keys,
        contains(keyFor(p1)));

    // person with new id, reusing existing key
    graph.getKeyForId('people', '221', keyIfAbsent: keyFor(p1));
    final p2 = Person(id: '221', name: 'Frank2', age: 32);
    expect(keyFor(p1), keyFor(p2));

    expect(
        (container.people.remoteAdapter.localAdapter
                as HiveLocalAdapter<Person>)
            .box!
            .keys,
        contains(keyFor(p2)));
  });

  test('equality', () async {
    /// Charles was once called Walter
    final p1a = Person(id: '2', name: 'Walter', age: 20);
    final p1b = Person(id: '2', name: 'Charles', age: 21);
    // they maintain same key as they're the same person
    expect(keyFor(p1a), keyFor(p1b));
    expect(p1a, isNot(p1b));
  });

  test('should work with subclasses', () {
    final dog = Dog(id: '2', name: 'Walker').saveLocal();
    final f = Familia(surname: 'Walker', dogs: {dog}.asHasMany).saveLocal();
    expect(f.dogs!.first.name, 'Walker');
  });

  test('data exception equality', () {
    final exception = Exception('whatever');
    expect(DataException(exception, statusCode: 410),
        DataException(exception, statusCode: 410));
    expect(DataException([exception], statusCode: 410),
        isNot(DataException(exception, statusCode: 410)));
  });

  test('delete models in iterable', () async {
    final adapter =
        container.dogs.remoteAdapter.localAdapter as HiveLocalAdapter;

    final initialLength = adapter.box!.length;

    final dogs = [
      Dog(id: '91', name: 'A').saveLocal(),
      Dog(id: '92', name: 'B').saveLocal(),
      Dog(id: '93', name: 'C').saveLocal(),
      Dog(id: '94', name: 'D').saveLocal()
    ];

    // box should now be initial + amount of saved dogs
    expect(adapter.box!.length, initialLength + dogs.length);

    dogs.deleteAll();

    // after deleting the iterable, we should be back where we started
    expect(adapter.box!.length, initialLength);
  });
}
