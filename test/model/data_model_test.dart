import 'package:flutter_data/flutter_data.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../_support/family.dart';
import '../_support/person.dart';
import '../_support/pet.dart';
import '../_support/setup.dart';
import '../mocks.dart';

void main() async {
  setUp(setUpFn);
  tearDown(tearDownFn);

  test('uninitialized throws an assertion error', () {
    final family = Family(id: '1', surname: 'Johnson');
    expectLater(family.save, throwsA(isA<AssertionError>()));
    expectLater(family.delete, throwsA(isA<AssertionError>()));
    expectLater(family.reload, throwsA(isA<AssertionError>()));
  });

  test('init', () async {
    final family = Family(id: '55', surname: 'Kelley').init(container.read);
    final model =
        Person(id: '1', name: 'John', age: 27, family: family.asBelongsTo)
            .init(container.read);

    // (1) it wires up the relationship (setOwnerInRelationship)
    expect(model.family.key, graph.getKeyForId('families', '55'));

    // (2) it saves the model locally
    expect(model, await personRepository.findOne(model.id!, remote: false));
  });

  test('findOne (reload) without ID', () async {
    final family = Family(surname: 'Zliedowski').init(container.read);
    final f2 = Family(surname: 'Zliedowski').was(family);

    final f3 = await family.reload(remote: false);
    expect(keyFor(family), keyFor(f2));
    expect(keyFor(family), keyFor(f3!));
  });

  test('delete model with and without ID', () async {
    final adapter = personRemoteAdapter.localAdapter;
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
        (personRemoteAdapter.localAdapter as HiveLocalAdapter<Person>)
            .box!
            .keys,
        contains(keyFor(p1)));

    // person with new id, reusing existing key
    graph.getKeyForId('people', '221', keyIfAbsent: keyFor(p1));
    final p2 = Person(id: '221', name: 'Frank2', age: 32).init(container.read);
    expect(keyFor(p1), keyFor(p2));

    expect(
        (personRemoteAdapter.localAdapter as HiveLocalAdapter<Person>)
            .box!
            .keys,
        contains(keyFor(p2)));
  });

  test('field equality and key equality', () async {
    /// [Person] is using field equality
    /// Charles was once called Agnes
    final p1a = Person(id: '2', name: 'Agnes', age: 20).init(container.read);
    final p1b = Person(id: '2', name: 'Charles', age: 21).init(container.read);
    // they maintain same key as they're the same person
    expect(keyFor(p1a), keyFor(p1b));
    expect(p1a, isNot(p1b));

    /// [Dog] is using key equality
    /// dog2 is the same dog who changed his name
    final dog = Dog(id: '2', name: 'Walker').init(container.read);
    final dog2 = Dog(id: '2', name: 'Mandarin').init(container.read);
    expect(keyFor(dog), keyFor(dog2));
    expect(dog, dog2);

    // both update

    final listener = Listener<DataState<Dog?>?>();

    final notifier = dogRepository.remoteAdapter
        .watchOneNotifier('2', remote: false, finder: 'dashboard');

    dispose = notifier.addListener(listener, fireImmediately: true);

    verify(listener(argThat(isA<Object>()))).called(1);
    verifyNoMoreInteractions(listener);

    Dog(id: '2', name: 'Tango').init(container.read);
    await oneMs();

    verify(listener(argThat(
            isA<DataState>().having((s) => s.model.name, 'name', 'Tango'))))
        .called(1);
    verifyNoMoreInteractions(listener);
  });

  test('should work with subclasses', () {
    final dog = Dog(id: '2', name: 'Walker').init(container.read);
    final f =
        Family(surname: 'Walker', dogs: {dog}.asHasMany).init(container.read);
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
