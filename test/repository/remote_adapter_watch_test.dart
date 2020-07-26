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
  tearDown(tearDownFn);

  test('watchAll', () async {
    final notifier = personRemoteAdapter.watchAll();

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
      await (() async {
        final id =
            Random().nextBool() ? Random().nextInt(999999999).toString() : null;
        person = Person.generate(owner, withId: id);

        // just before finishing, delete last Person
        if (j == count - 1) {
          await person.delete();
        }
        await oneMs();
      })();
    }
  });

  test('watchAll updates', () async {
    final listener = Listener<DataState<List<Person>>>();

    final p1 = Person(id: '1', name: 'Zof', age: 23).init(owner);
    final notifier = personRemoteAdapter.watchAll();

    dispose = notifier.addListener(listener, fireImmediately: true);

    verify(listener(DataState([p1], isLoading: true))).called(1);
    verifyNoMoreInteractions(listener);

    final p2 = Person(id: '1', name: 'Zofie', age: 23).init(owner);
    await oneMs();

    verify(listener(DataState([p2], isLoading: false))).called(1);
    verifyNoMoreInteractions(listener);

    // since p3 is not init() it won't show up thru watchAll
    final p3 = Person(id: '1', name: 'Zofien', age: 23);
    await oneMs();

    verifyNever(listener(DataState([p3], isLoading: false)));
    verifyNoMoreInteractions(listener);
  });

  test('watchOne', () async {
    final listener = Listener<DataState<Person>>();

    final notifier = personRemoteAdapter.watchOne('1');

    final matcher = (name) => isA<DataState<Person>>()
        .having((s) => s.model.id, 'id', '1')
        .having((s) => s.model.name, 'name', name);

    dispose = notifier.addListener(listener, fireImmediately: false);

    Person(id: '1', name: 'Frank', age: 30).init(owner);
    await oneMs();

    verify(listener(argThat(matcher('Frank')))).called(1);
    verifyNoMoreInteractions(listener);

    await personRemoteAdapter.save(Person(id: '1', name: 'Steve-O', age: 34));
    await oneMs();

    verify(listener(argThat(matcher('Steve-O')))).called(1);
    verifyNoMoreInteractions(listener);

    await personRemoteAdapter.save(Person(id: '1', name: 'Liam', age: 36));
    await oneMs();

    verify(listener(argThat(matcher('Liam')))).called(1);
    verifyNoMoreInteractions(listener);

    // a different ID doesn't trigger an extra call to expectAsync1(count=3)
    await personRemoteAdapter.save(Person(id: '2', name: 'Jupiter', age: 3));
    await oneMs();

    verifyNever(listener(argThat(matcher('Jupiter'))));
    verifyNoMoreInteractions(listener);
  });

  test('watchOne reads latest version', () async {
    Person(id: '345', name: 'Frank', age: 30).init(owner);
    Person(id: '345', name: 'Steve-O', age: 34).init(owner);

    final notifier = personRemoteAdapter.watchOne('345');

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
    );

    final notifier = familyRemoteAdapter.watchOne('22',
        alsoWatch: (family) => [family.persons, family.residence]);

    final listener = Listener<DataState<Family>>();

    dispose = notifier.addListener(listener);

    verify(listener(argThat(isA<DataState<Family>>()))).called(1);
    verifyNoMoreInteractions(listener);

    final p1 = Person(id: '1', name: 'Frank', age: 16).init(owner);
    p1.family.value = f1;
    await oneMs();

    verify(listener(argThat(
      withState<Family>((s) => s.model.persons, hasLength(1)),
    ))).called(1);
    verifyNoMoreInteractions(listener);

    f1.persons.add(Person(name: 'Martin', age: 44)); // this time without init
    await oneMs();

    verify(listener(argThat(
      withState<Family>((s) => s.model.persons, hasLength(2)),
    ))).called(1);
    verifyNoMoreInteractions(listener);

    f1.residence.value = House(address: '123 Main St'); // no init
    await oneMs();

    verify(listener(argThat(
      withState<Family>((s) => s.model.residence.value.address, '123 Main St'),
    ))).called(1);
    verifyNoMoreInteractions(listener);

    f1.persons.remove(p1);
    await oneMs();

    verify(listener(argThat(
      withState<Family>((s) => s.model.persons, hasLength(1)),
    ))).called(1);
    verifyNoMoreInteractions(listener);

    // a non-watched relationship does not trigger

    f1.cottage.value = House(address: '7342 Mountain Rd');
    await oneMs();

    verifyNever(listener(any));
    verifyNoMoreInteractions(listener);

    await f1.delete();
    await oneMs();

    verify(listener(argThat(
      withState<Family>((s) => s.model, isNull),
    ))).called(1);
    verifyNoMoreInteractions(listener);
  });

  test('watchOne without ID and alsoWatch', () async {
    final frank = Person(name: 'Frank', age: 30).init(owner);

    final notifier = frank.watch(alsoWatch: (p) => [p.family]);

    final listener = Listener<DataState<Person>>();
    dispose = notifier.addListener(listener, fireImmediately: false);

    final matcher = isA<DataState<Person>>()
        .having((s) => s.model.name, 'name', 'Steve-O')
        .having((s) => s.hasException, 'exception', isFalse)
        .having((s) => s.isLoading, 'loading', isFalse);

    verifyNever(listener(argThat(matcher)));
    verifyNoMoreInteractions(listener);

    final steve = Person(name: 'Steve-O', age: 30).was(frank);
    await oneMs();

    verify(listener(argThat(matcher))).called(1);
    verifyNoMoreInteractions(listener);

    final family = Family(surname: 'Marquez');
    steve.family.value = family;
    await oneMs();

    verify(listener(argThat(matcher))).called(1);
    verifyNoMoreInteractions(listener);

    Family(surname: 'Thomson').was(family);
    await oneMs();

    verify(listener(argThat(matcher))).called(1);
    verifyNoMoreInteractions(listener);
  });
}
