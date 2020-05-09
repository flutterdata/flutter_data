import 'package:flutter_data/flutter_data.dart';
import 'package:test/test.dart';

import '../../models/person.dart';
import '../setup.dart';

void main() async {
  setUpAll(setUpAllFn);
  tearDownAll(tearDownAllFn);

  test('watchAll', () async {
    var repo = injection.locator<Repository<Person>>();
    // make sure there are no items in local storage from previous tests
    await repo.box.clear();
    expect(repo.box.keys, isEmpty);

    var notifier = repo.watchAll();

    final matcher = predicate((p) {
      return p is Person && p.name.startsWith('zzz-') && p.age < 19;
    });

    for (var i = 0; i < 3; i++) {
      Person.generateRandom(repo);
      var dispose = notifier.addListener((state) {
        if (i == 0) expect(state.model, isNull);
        if (i == 1) expect(state.model, [matcher]);
        if (i == 2) expect(state.model, [matcher, matcher]);
        if (i == 3) expect(state.model, [matcher, matcher, matcher]);
      }, fireImmediately: false);
      dispose();
    }

    // TODO: test addListener continuously - via expectAsync1 (but it's difficult to work with)

    expect(repo.box.keys.length, 3);
  });

  test('watchOne', () async {
    var repo = injection.locator<Repository<Person>>();
    // make sure there are no items in local storage from previous tests
    await repo.box.clear();
    expect(repo.box.keys, isEmpty);

    var notifier = repo.watchOne('1');

    final matcher = (name) => predicate((p) {
          return p is Person && p.name == name;
        });

    for (var i = 0; i < 3; i++) {
      if (i == 1) await repo.save(Person(id: '1', name: 'Frank', age: 30));
      if (i == 2) await repo.save(Person(id: '1', name: 'Steve-O', age: 34));
      if (i == 3) await repo.save(Person(id: '1', name: 'Liam', age: 34));
      var dispose = notifier.addListener((state) {
        if (i == 0) expect(state.model, isNull);
        if (i == 1) expect(state.model, matcher('Frank'));
        if (i == 2) expect(state.model, matcher('Steve-O'));
        if (i == 3) expect(state.model, matcher('Liam'));
      }, fireImmediately: false);
      dispose();
    }
  });
}
