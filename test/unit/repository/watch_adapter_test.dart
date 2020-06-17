import 'dart:math';

import 'package:flutter_data/flutter_data.dart';
import 'package:test/test.dart';

import '../../models/family.dart';
import '../../models/house.dart';
import '../../models/person.dart';
import '../setup.dart';

void main() async {
  setUpAll(setUpAllFn);
  tearDownAll(tearDownAllFn);

  Repository<Person> repository;
  Function dispose;

  setUp(() async {
    repository = injection.locator<Repository<Person>>();
    // make sure there are no items in local storage from previous tests
    await repository.box.clear();
    repository.manager.graph.clear();
    expect(repository.box.keys, isEmpty);
  });

  tearDown(() {
    dispose();
  });

  test('watchAll', () async {
    final notifier = repository.watchAll();

    final matcher = predicate((p) {
      return p is Person && p.name.startsWith('Person Number') && p.age < 19;
    });

    final count = 18;
    var i = 0;
    dispose = notifier.addListener(
      expectAsync1((state) {
        if (i == 0) {
          expect(state.model, [matcher]);
        } else if (i == 1) {
          expect(state.model, [matcher, matcher]);
        } else if (i == 2) {
          expect(state.model, [matcher, matcher, matcher]);
        } else if (i < count) {
          expect(state.model, hasLength(i + 1));
        } else if (i == count) {
          // the last event was a deletion, NOT an addition
          // so instead of expecting i+1, we expect i-1
          expect(state.model, hasLength(i - 1));
          expect(repository.box.keys.length, i - 1);
        }
        i++;
      }, count: count + 1),
      fireImmediately: false,
    );

    // this whole thing below emits count + 1 (watchAll-relevant) states
    Person person;
    for (var j = 0; j < count; j++) {
      final id =
          Random().nextBool() ? Random().nextInt(999999999).toString() : null;
      person = Person.generate(manager, withId: id);
      if (Random().nextBool()) {
        Family(surname: 'Snowden ${Random().nextDouble()}').init(manager);
      }

      // in addition, delete last Person
      if (j == count - 1) {
        await person.delete();
      }
    }
  });

  test('watchAll updates', () async {
    final notifier = repository.watchAll();

    Person(id: '1', name: 'Zof', age: 23).init(manager);

    var i = 0;
    dispose = notifier.addListener(
      expectAsync1((state) {
        if (i == 0) expect(state.model, hasLength(1));
        if (i == 1) expect(state.model, hasLength(1));
        i++;
      }, count: 2),
      fireImmediately: true,
    );

    Person(id: '1', name: 'Zofie', age: 23).init(manager);
  });

  test('watchOne', () async {
    final notifier = repository.watchOne('1');

    final matcher = (name) =>
        predicate((p) => p is Person && p.id == '1' && p.name == name);

    var i = 0;
    dispose = notifier.addListener(
      expectAsync1((state) {
        if (i == 0) expect(state.model, matcher('Frank'));
        if (i == 1) expect(state.model, matcher('Steve-O'));
        if (i == 2) expect(state.model, matcher('Liam'));
        i++;
      }, count: 3),
      fireImmediately: false,
    );

    Person(id: '1', name: 'Frank', age: 30).init(manager);
    await repository.save(Person(id: '1', name: 'Steve-O', age: 34));
    await repository.save(Person(id: '1', name: 'Liam', age: 36));
    // a different ID doesn't trigger an extra call to expectAsync1(count=3)
    await repository.save(Person(id: '2', name: 'Jupiter', age: 3));
  });

  test('watchOne reads latest version', () async {
    final notifier = repository.watchOne('345');

    Person(id: '345', name: 'Frank', age: 30).init(manager);
    Person(id: '345', name: 'Steve-O', age: 34).init(manager);

    dispose = notifier.addListener(
      expectAsync1((state) {
        expect(state.model.name, 'Steve-O');
      }),
    );
  });

  test('watchOne with alsoWatch relationships', () async {
    final familyRepository = injection.locator<Repository<Family>>();
    final notifier = familyRepository.watchOne('22',
        alsoWatch: (family) => [family.persons, family.residence]);

    final f1 = Family(
      id: '22',
      surname: 'Abagnale',
      persons: HasMany(),
      residence: BelongsTo(),
      cottage: BelongsTo(),
    ).init(manager);

    var i = 0;
    dispose = notifier.addListener(
      expectAsync1((state) {
        if (i == 0) expect(state.model, isA<Family>());
        if (i == 1) expect(state.model.persons, hasLength(1));
        if (i == 2) expect(state.model.persons, hasLength(2));
        if (i == 3) expect(state.model.residence.value.address, '123 Main St');
        if (i == 4) expect(state.model.persons, hasLength(1));
        if (i == 5) expect(state.model, isNull);
        i++;
      }, count: 6),
    );

    final p1 = Person(id: '1', name: 'Frank', age: 16).init(manager);
    p1.family.value = f1;
    f1.persons.add(Person(name: 'Martin', age: 44).init(manager));
    f1.residence.value = House(address: '123 Main St').init(manager);
    f1.persons.remove(p1);

    // a non-watched relationship does not trigger
    f1.cottage.value = House(address: '7342 Mountain Rd').init(manager);

    await f1.delete();
  });

  test('watchOne without ID and alsoWatch', () async {
    final frank = Person(name: 'Frank', age: 30).init(manager);

    final notifier = frank.watch(alsoWatch: (p) => [p.family]);
    dispose = notifier.addListener(
      // it will be hit three times
      // (1) by Steve-O
      // (2) by the Family relationship
      // (3) by a change in the watched Family model
      expectAsync1((state) {
        expect(state.model.name, 'Steve-O');
      }, count: 3),
      fireImmediately: false,
    );

    final steve =
        Person(name: 'Steve-O', age: 30).init(manager, key: keyFor(frank));
    steve.family.value = Family(id: '922', surname: 'Marquez').init(manager);

    Family(id: '922', surname: 'Thomson').init(manager);
  });
}
