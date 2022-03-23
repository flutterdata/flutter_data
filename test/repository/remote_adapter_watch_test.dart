import 'dart:math';

import 'package:flutter_data/flutter_data.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../_support/family.dart';
import '../_support/house.dart';
import '../_support/person.dart';
import '../_support/setup.dart';
import '../mocks.dart';

void main() async {
  setUp(setUpFn);
  tearDown(tearDownFn);

  test('should be able to watch, dispose and watch again', () async {
    final notifier = personRemoteAdapter.watchAllNotifier();
    dispose = notifier.addListener((_) {});
    dispose!();
    final notifier2 = personRemoteAdapter.watchAllNotifier();
    dispose = notifier2.addListener((_) {});
  });

  test('watchAllNotifier', () async {
    final notifier = personRemoteAdapter.watchAllNotifier();

    final matcher = predicate((p) {
      return p is Person && p.name.startsWith('Person Number') && p.age! < 19;
    });

    final count = 29;
    var i = 0;
    dispose = notifier.addListener(
      expectAsync1((state) {
        if (i == 0) {
          expect(state.model, [matcher]);
          expect(state.isLoading, isFalse);
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
                  .box!
                  .keys
                  .length,
              i - 1);
          expect(state.isLoading, false); // since it's not hitting any API
        }
        i++;
      }, count: count - 1),
      fireImmediately: false,
    );

    // this whole thing below emits count + 1 (watchAllNotifier-relevant) states
    Person person;
    for (var j = 0; j < count; j++) {
      await (() async {
        final id =
            Random().nextBool() ? Random().nextInt(999999999).toString() : null;
        person = Person.generate(container, withId: id);

        // just before finishing, delete last Person
        if (j == count - 1) {
          await person.delete();
        }
        await oneMs();
      })();
    }
  });

  test('watchAllNotifier updates', () async {
    final listener = Listener<DataState<List<Person>>>();

    final p1 = Person(id: '1', name: 'Zof', age: 23).init(container.read);
    final notifier = personRemoteAdapter.watchAllNotifier(remote: true);

    dispose = notifier.addListener(listener, fireImmediately: true);

    verify(listener(DataState([p1], isLoading: true))).called(1);
    verifyNoMoreInteractions(listener);

    final p2 = Person(id: '1', name: 'Zofie', age: 23).init(container.read);
    await oneMs();

    verify(listener(DataState([p2], isLoading: false))).called(1);
    verifyNoMoreInteractions(listener);

    // since p3 is not init() it won't show up thru watchAllNotifier
    final p3 = Person(id: '1', name: 'Zofien', age: 23);
    await oneMs();

    verifyNever(listener(DataState([p3], isLoading: false)));
    verifyNoMoreInteractions(listener);
  });

  test('watchAllNotifier with where/map', () async {
    final listener = Listener<DataState<List<Person>>>();

    Person(id: '1', name: 'Zof', age: 23).init(container.read);
    Person(id: '2', name: 'Sarah', age: 50).init(container.read);
    Person(id: '3', name: 'Walter', age: 11).init(container.read);
    Person(id: '4', name: 'Koen', age: 92).init(container.read);

    final notifier = personRemoteAdapter
        .watchAllNotifier(remote: false)
        .where((p) => p.age! < 40)
        .map((p) => Person(name: p.name, age: p.age! + 10));

    dispose = notifier.addListener(listener, fireImmediately: true);

    verify(listener(DataState(
      [Person(name: 'Zof', age: 33), Person(name: 'Walter', age: 21)],
    ))).called(1);
    verifyNoMoreInteractions(listener);
  });

  test('watchOneNotifier', () async {
    final listener = Listener<DataState<Person?>?>();

    final notifier = personRemoteAdapter.watchOneNotifier('1');

    final matcher = (name) => isA<DataState>()
        .having((s) => s.model.id, 'id', '1')
        .having((s) => s.model.name, 'name', name);

    dispose = notifier.addListener(listener, fireImmediately: false);

    Person(id: '1', name: 'Frank', age: 30).init(container.read);
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

  test('watchOneNotifier reads latest version', () async {
    Person(id: '345', name: 'Frank', age: 30).init(container.read);
    Person(id: '345', name: 'Steve-O', age: 34).init(container.read);

    final notifier = personRemoteAdapter.watchOneNotifier('345');

    dispose = notifier.addListener(expectAsync1((state) {
      expect(state.model!.name, 'Steve-O');
    }), fireImmediately: true);
  });

  test('watchOneNotifier with alsoWatch relationships', () async {
    final f1 = Family(
      id: '22',
      surname: 'Abagnale',
      persons: HasMany(),
      residence: BelongsTo(),
      cottage: BelongsTo(),
    );

    final notifier = familyRemoteAdapter.watchOneNotifier('22',
        alsoWatch: (family) => [family.persons, family.residence!],
        remote: true);

    final listener = Listener<DataState<Family?>?>();

    dispose = notifier.addListener(listener, fireImmediately: true);

    verify(listener(
      argThat(isA<DataState>().having((s) => s.isLoading, '', true)),
    )).called(1);
    verifyNoMoreInteractions(listener);

    await oneMs();

    final p1 = Person(id: '1', name: 'Frank', age: 16).init(container.read);
    p1.family.value = f1;
    await oneMs();

    final matcher = isA<DataState>()
        .having((s) => s.model.persons, 'name', hasLength(1))
        .having((s) => s.hasModel, 'hasModel', true)
        .having((s) => s.hasException, 'hasException', false)
        .having((s) => s.isLoading, 'isLoading', false);

    verify(listener(argThat(matcher))).called(1);

    f1.persons.add(Person(name: 'Martin', age: 44)); // this time without init
    await oneMs();

    verify(listener(argThat(
      isA<DataState>().having((s) => s.model.persons!, 'persons', hasLength(2)),
    ))).called(1);
    verifyNoMoreInteractions(listener);

    f1.residence!.value = House(address: '123 Main St'); // no init
    await oneMs();

    verify(listener(argThat(
      isA<DataState>().having(
          (s) => s.model.residence!.value!.address, 'address', '123 Main St'),
    ))).called(1);
    verifyNoMoreInteractions(listener);

    f1.persons.remove(p1);
    await oneMs();

    verify(listener(argThat(
      isA<DataState>().having((s) => s.model.persons!, 'persons', hasLength(1)),
    ))).called(1);
    verifyNoMoreInteractions(listener);

    // a non-watched relationship does not trigger

    f1.cottage!.value = House(address: '7342 Mountain Rd');
    await oneMs();

    verifyNever(listener(any));
    verifyNoMoreInteractions(listener);

    await f1.delete();
    await oneMs();

    verify(listener(argThat(
      isA<DataState>().having((s) => s.model, 'model', isNull),
    ))).called(1);
    verifyNoMoreInteractions(listener);
  });

  test('watchOneNotifier without ID and alsoWatch', () async {
    final frank = Person(name: 'Frank', age: 30).init(container.read);

    final notifier = personRepository.remoteAdapter
        .watchOneNotifier(frank, alsoWatch: (p) => [p.family]);

    final listener = Listener<DataState<Person?>?>();
    dispose = notifier.addListener(listener, fireImmediately: false);

    final matcher = isA<DataState>()
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

  test('watchOneNotifier with where/map', () async {
    final listener = Listener<DataState<Person?>>();

    Person(id: '1', name: 'Zof', age: 23).init(container.read);

    final notifier = personRemoteAdapter
        .watchOneNotifier('1', remote: false)
        .map((p) => Person(name: p!.name, age: p.age! + 10))
        .where((p) => p!.age! < 40);

    dispose = notifier.addListener(listener, fireImmediately: true);

    verify(listener(DataState(
      Person(name: 'Zof', age: 33),
    ))).called(1);
    verifyNoMoreInteractions(listener);

    Person(id: '1', name: 'Zof', age: 71).init(container.read);
    await oneMs();

    // since 71 + 10 > 40, the listener will receive a null
    verify(listener(DataState(null))).called(1);
    verifyNoMoreInteractions(listener);
  });
}
