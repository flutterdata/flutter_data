import 'package:flutter_data/flutter_data.dart';
import 'package:test/test.dart';

import '../_support/familia.dart';
import '../_support/node.dart';
import '../_support/person.dart';
import '../_support/pet.dart';
import '../_support/setup.dart';

void main() async {
  setUp(setUpFn);
  tearDown(tearDownFn);

  test('save', () async {
    final familia = Familia(id: '55', surname: 'Kelley');
    expect(container.familia.findOneLocalById('55'), isNull);

    final person =
        Person(id: '1', name: 'John', age: 27, familia: familia.asBelongsTo);
    await person.save();

    // (1) it wires up the relationship
    expect(person.familia.key, core.getKeyForId('familia', '55'));

    // (2) it saves the model locally
    final e2 = container.people.findOneLocalById(person.id!);
    expect(e2, person);
  });

  test('on model init', () async {
    Node(id: 3, name: 'child');
    // child is saved on model init, so it should find it
    final result = container.nodes.findOneLocalById(3);
    expect(result!.id, 3);
  });

  test('findOne (remote and local reload)', () async {
    var familia = await Familia(id: '1', surname: 'Perez').save();
    familia = Familia(id: '1', surname: 'Perez Gomez');

    container.read(responseProvider.notifier).state = TestResponse.json('''
        { "id": "1", "surname": "Perez" }
      ''');

    familia = await familia.reload() as Familia;
    expect(familia, Familia(id: '1', surname: 'Perez'));
    expect(await container.familia.findOne('1'),
        Familia(id: '1', surname: 'Perez'));

    var f2 = Familia(id: '1', surname: 'Perez Lopez');
    f2.saveLocal();
    expect(familia.surname, isNot('Perez Lopez'));
    familia = familia.reloadLocal()!;
    expect(familia.surname, equals('Perez Lopez'));
  });

  test('delete model with and without ID', () async {
    final adapter = container.people;
    // create a person WITH ID and assert it's there
    final person = Person(id: '21103', name: 'John', age: 54).saveLocal();
    expect(adapter.findAllLocal(), hasLength(1));

    // delete that person and assert it's not there
    await person.delete();
    expect(adapter.findAllLocal(), hasLength(0));

    // create a person WITHOUT ID and assert it's there
    final person2 = Person(name: 'Peter', age: 101).saveLocal();
    expect(adapter.findAllLocal(), hasLength(1));

    // delete that person (this time via `deleteLocal`) and assert it's not there
    person2.deleteLocal();
    expect(adapter.findAllLocal(), hasLength(0));
  });

  // test('should reuse key', () {
  //   // id-less person
  //   final p1 = Person(name: 'Frank', age: 20).saveLocal();
  //   expect(
  //       container.people.keys,
  //       contains(keyFor(p1)));

  //   // person with new id, reusing existing key
  //   // core.getKeyForId('people', '221');
  //   final p2 = Person(id: '221', name: 'Frank2', age: 32);
  //   // expect(keyFor(p1), keyFor(p2));

  //   expect(
  //       container.people.keys,
  //       contains(keyFor(p2)));
  // });

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
}
