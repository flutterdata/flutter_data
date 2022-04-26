import 'package:flutter_data/flutter_data.dart';
import 'package:test/test.dart';

import '../_support/familia.dart';
import '../_support/person.dart';
import '../_support/pet.dart';
import '../_support/setup.dart';

void main() async {
  setUp(setUpFn);
  tearDown(tearDownFn);

  test('uninitialized throws an assertion error', () {
    final familia = Familia(id: '1', surname: 'Johnson');
    expectLater(familia.save, throwsA(isA<AssertionError>()));
    expectLater(familia.delete, throwsA(isA<AssertionError>()));
    expectLater(familia.refresh, throwsA(isA<AssertionError>()));
  });

  test('init', () async {
    final familia = Familia(id: '55', surname: 'Kelley').init(container.read);
    final model =
        Person(id: '1', name: 'John', age: 27, familia: familia.asBelongsTo)
            .init(container.read);

    // (1) it wires up the relationship (setOwnerInRelationship)
    expect(model.familia.key, graph.getKeyForId('familia', '55'));

    // (2) it saves the model locally
    expect(model, await container.people.findOne(model.id!, remote: false));
  });

  test('findOne (reload)', () async {
    final familia = Familia(id: '1', surname: 'Perez').init(container.read);
    final f2 = Familia(id: '1', surname: 'Perez').was(familia);

    final f3 = await familia.reload(remote: false);
    expect(keyFor(familia), keyFor(f2));
    expect(keyFor(familia), keyFor(f3!));
  });

  test('findOne (refresh) without ID', () async {
    final familia = Familia(surname: 'Zliedowski').init(container.read);
    final f2 = Familia(surname: 'Zliedowski').was(familia);

    final f3 = familia.refresh();
    expect(keyFor(familia), keyFor(f2));
    expect(keyFor(familia), keyFor(f3));
  });

  test('delete model with and without ID', () async {
    final adapter = container.people.remoteAdapter.localAdapter;
    // create a person WITH ID and assert it's there
    final person =
        Person(id: '21103', name: 'John', age: 54).init(container.read);
    expect(adapter.findAll(), hasLength(1));

    // delete that person and assert it's not there
    await person.delete();
    expect(adapter.findAll(), hasLength(0));

    // create a person WITHOUT ID and assert it's there
    final person2 = Person(name: 'Peter', age: 101).init(container.read);
    expect(adapter.findAll(), hasLength(1));

    // delete that person and assert it's not there
    await person2.delete();
    expect(adapter.findAll(), hasLength(0));
  });

  test('should reuse key', () {
    // id-less person
    final p1 = Person(name: 'Frank', age: 20).init(container.read);
    expect(
        (container.people.remoteAdapter.localAdapter
                as HiveLocalAdapter<Person>)
            .box!
            .keys,
        contains(keyFor(p1)));

    // person with new id, reusing existing key
    graph.getKeyForId('people', '221', keyIfAbsent: keyFor(p1));
    final p2 = Person(id: '221', name: 'Frank2', age: 32).init(container.read);
    expect(keyFor(p1), keyFor(p2));

    expect(
        (container.people.remoteAdapter.localAdapter
                as HiveLocalAdapter<Person>)
            .box!
            .keys,
        contains(keyFor(p2)));
  });

  test('was should not allow a different ID', () async {
    final f1 = Familia(id: '1', surname: 'Perez').init(container.read);
    expect(() {
      Familia(id: '2', surname: 'Perez').was(f1);
    }, throwsA(isA<AssertionError>()));
  });

  test('equality', () async {
    /// [Person] is using field equality
    /// Charles was once called Agnes
    final p1a = Person(id: '2', name: 'Agnes', age: 20).init(container.read);
    final p1b = Person(id: '2', name: 'Charles', age: 21).init(container.read);
    // they maintain same key as they're the same person
    expect(keyFor(p1a), keyFor(p1b));
    expect(p1a, isNot(p1b));
  });

  test('should work with subclasses', () {
    final dog = Dog(id: '2', name: 'Walker').init(container.read);
    final f =
        Familia(surname: 'Walker', dogs: {dog}.asHasMany).init(container.read);
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
