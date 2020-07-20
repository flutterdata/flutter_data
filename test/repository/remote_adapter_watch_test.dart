import 'dart:math';

import 'package:flutter_data/flutter_data.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../_support/family.dart';
import '../_support/house.dart';
import '../_support/mocks.dart';
import '../_support/person.dart';
import '../_support/setup.dart';

void main() async {
  setUp(setUpFn);

  Function dispose;
  tearDown(() {
    dispose?.call();
  });

  test('watchAll', () async {
    final notifier = personRepository.watchAll();

    final matcher = predicate((p) {
      return p is Person && p.name.startsWith('Person Number') && p.age < 19;
    });

    final count = 29;
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
          expect(
              (personRemoteAdapter.localAdapter as HiveLocalAdapter<Person>)
                  .box
                  .keys
                  .length,
              i - 1);
          expect(state.isLoading, false); // since it's not hitting any API
        }
        i++;
      }, count: count),
      fireImmediately: false,
    );

    // this whole thing below emits count + 1 (watchAll-relevant) states
    Person person;
    for (var j = 0; j < count; j++) {
      await runAndWait(() async {
        final id =
            Random().nextBool() ? Random().nextInt(999999999).toString() : null;
        person = Person.generate(owner, withId: id);
        if (Random().nextBool()) {
          Family(surname: 'Snowden ${Random().nextDouble()}').init(owner);
        }

        // in addition, delete last Person
        if (j == count - 1) {
          await person.delete();
        }
      });
    }
  });

  test('watchAll updates', () async {
    final listener1 = Listener<DataState<List<Person>>>();

    final p1 = Person(id: '1', name: 'Zof', age: 23).init(owner);
    final notifier = personRepository.watchAll();

    dispose = notifier.addListener(listener1, fireImmediately: true);

    verify(listener1(DataState([p1], isLoading: true))).called(1);
    verifyNoMoreInteractions(listener1);

    final p2 = Person(id: '1', name: 'Zofie', age: 23);
    await runAndWait(() => p2.init(owner));

    verify(listener1(DataState([p2], isLoading: false))).called(1);
    verifyNoMoreInteractions(listener1);

    // since p3 is not init() it won't show up thru watchAll
    final p3 = Person(id: '1', name: 'Zofien', age: 23);
    await runAndWait(() => p3);

    verifyNever(listener1(DataState([p3], isLoading: false)));
    verifyNoMoreInteractions(listener1);
  });

  test('watchOne', () async {
    final notifier = personRepository.watchOne('1');

    final matcher = (name) => isA<Person>()
        .having((p) => p.id, 'id', '1')
        .having((p) => p.name, 'name', name);

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

    await runAndWait(() => Person(id: '1', name: 'Frank', age: 30).init(owner));
    await runAndWait(
        () => personRepository.save(Person(id: '1', name: 'Steve-O', age: 34)));
    await runAndWait(
        () => personRepository.save(Person(id: '1', name: 'Liam', age: 36)));

    // a different ID doesn't trigger an extra call to expectAsync1(count=3)
    await runAndWait(
        () => personRepository.save(Person(id: '2', name: 'Jupiter', age: 3)));
  });

  test('watchOne reads latest version', () async {
    Person(id: '345', name: 'Frank', age: 30).init(owner);
    Person(id: '345', name: 'Steve-O', age: 34).init(owner);

    final notifier = personRepository.watchOne('345');

    dispose = notifier.addListener(
      expectAsync1((state) {
        expect(state.model.name, 'Steve-O');
      }),
    );
  });

  test('watchOne with alsoWatch relationships', () async {
    final f1 = Family(
      id: '22',
      surname: 'Abagnale',
      persons: HasMany(),
      residence: BelongsTo(),
      cottage: BelongsTo(),
    ).init(owner);

    final notifier = familyRepository.watchOne('22',
        alsoWatch: (family) => [family.persons, family.residence]);

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

    Person p1;
    await runAndWait(() {
      p1 = Person(id: '1', name: 'Frank', age: 16).init(owner);
      p1.family.value = f1;
    });

    await runAndWait(() {
      f1.persons.add(Person(name: 'Martin', age: 44).init(owner));
    });

    await runAndWait(
        () => f1.residence.value = House(address: '123 Main St').init(owner));

    await runAndWait(() => f1.persons.remove(p1));

    // a non-watched relationship does not trigger
    await runAndWait(() =>
        f1.cottage.value = House(address: '7342 Mountain Rd').init(owner));

    await runAndWait(() => f1.delete());
  });

  test('watchOne without ID and alsoWatch', () async {
    final frank = Person(name: 'Frank', age: 30).init(owner);

    final notifier = frank.watch(alsoWatch: (p) => [p.family]);
    dispose = notifier.addListener(
      // it will be hit three times
      // (1) by Steve-O
      // (2) by the Family relationship
      // (3) by a change in the watched Family model
      expectAsync1((state) {
        expect(state.model.name, 'Steve-O');
        expect(state.hasException, false);
        expect(state.isLoading, false);
      }, count: 3),
      fireImmediately: false,
    );

    Person steve;
    Family family;
    await runAndWait(() => steve = Person(name: 'Steve-O', age: 30).was(frank));

    await runAndWait(() {
      family = Family(surname: 'Marquez').init(owner);
      steve.family.value = family;
    });

    await runAndWait(() => Family(surname: 'Thomson').was(family));
  });
}
