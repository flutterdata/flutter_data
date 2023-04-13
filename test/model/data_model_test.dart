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
    final child = Node(id: 3, name: 'child');
    // child is saved on model init, so it should find it
    expect(await container.nodes.findOne(3), child);
  });

  test('withKeyOf', () {
    final p = Person(id: '1', name: 'Peter');
    final p2 = Person(id: '2', name: 'Petera');
    // keys are different
    expect(keyFor(p), isNot(keyFor(p2)));

    p2.withKeyOf(p);

    // now both objects have the same key
    expect(keyFor(p), keyFor(p2));

    // now the original key is associated to id=2
    expect(graph.getKeyForId('people', '1'), isNull);
    expect(graph.getKeyForId('people', '2'), keyFor(p));

    //

    final p3 = Person(name: 'Robert');
    final p4 = Person(name: 'Roberta');

    expect(keyFor(p3), isNot(keyFor(p4)));
    p4.withKeyOf(p3);
    expect(keyFor(p3), keyFor(p4));

    // passing in a null-ID model

    final p5 = Person(name: 'Thiago');
    final p6 = Person(id: '7', name: 'Thiaga');

    expect(keyFor(p5), isNot(keyFor(p6)));

    p6.withKeyOf(p5);

    // the original key remains associated to id=7
    expect(graph.getKeyForId('people', '7'), keyFor(p6));
    // and p5 also has the old key
    expect(keyFor(p5), keyFor(p6));

    // force passed-in model's key

    final p5b = Person(name: 'Thiago');
    final p6b = Person(id: '17', name: 'Thiaga');
    final p5bk = keyFor(p5b);
    final p6bk = keyFor(p6b);

    expect(p5bk, isNot(p6bk));

    p6b.withKeyOf(p5b, force: true);

    // the new key is associated to id=17
    expect(graph.getKeyForId('people', '17'), p5bk);
    // and p6b (original model) has the new key
    expect(keyFor(p5b), keyFor(p6b));

    //

    final p7 = Person(id: '8', name: 'Evo');
    final p8 = Person(name: 'Eva');

    expect(keyFor(p7), isNot(keyFor(p8)));

    p8.withKeyOf(p7);
    expect(keyFor(p7), keyFor(p8));

    // now no key is associated to id=8
    expect(graph.getKeyForId('people', '8'), keyFor(p7));
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
