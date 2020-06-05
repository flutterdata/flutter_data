import 'dart:async';
import 'dart:math';

import 'package:flutter_data/flutter_data.dart';
import 'package:test/test.dart';

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
    repository.manager.graphNotifier.clear();
    expect(repository.box.keys, isEmpty);
  });

  tearDown(() {
    dispose();
  });

  test('watchAll', () async {
    final notifier = repository.watchAll();

    final matcher = predicate((p) {
      return p is Person && p.name.startsWith('zzz-') && p.age < 19;
    });

    notifier.onError = Zone.current.handleUncaughtError;

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
        } else {
          expect(state.model, hasLength(i + 1));
        }
        i++;
      }, count: count),
      fireImmediately: false,
    );

    for (var j = 0; j < count; j++) {
      Person.generateRandom(repository, withId: Random().nextBool());
    }

    expect(repository.box.keys.length, count);
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

    Person(id: '1', name: 'Frank', age: 30).init(repository);
    await repository.save(Person(id: '1', name: 'Steve-O', age: 34));
    await repository.save(Person(id: '1', name: 'Liam', age: 36));
    // a different ID doesn't trigger an extra call to expectAsync1(count=3)
    await repository.save(Person(id: '2', name: 'Jupiter', age: 3));
  });
}
