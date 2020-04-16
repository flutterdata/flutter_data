import 'package:flutter_data/flutter_data.dart';
import 'package:test/test.dart';
import 'package:async/async.dart';

import 'models/family.dart';
import 'models/house.dart';
import 'models/person.dart';
import 'setup.dart';

void main() async {
  setUpAll(setUpAllFn);
  tearDownAll(tearDownAllFn);

  test('create', () {
    var repo = injection.locator<Repository<Person>>();
    final manager = repo.manager;

    var family = Family(id: "55", surname: 'Kelley');
    var model =
        Person(id: '1', name: "John", age: 27, family: family.asBelongsTo)
            .init(repo);

    // (1) it wires up the relationship (setOwnerInRelationship)
    expect(model.family.key, manager.dataId<Family>("55").key);

    // (2) it saves the model locally
    expect(model, repo.localAdapter.findOne(model.key));
  });

  test('locator', () {
    var repo = injection.locator<Repository<Person>>();
    expect(repo.manager.locator, isNotNull);
  });

  test('serialize with relationships', () {
    var repo = injection.locator<Repository<Family>>();

    var person = Person(id: '1', name: "John", age: 37);
    var house = House(id: '1', address: "123 Main St");
    var family = Family(
            id: "1",
            surname: "Smith",
            house: house.asBelongsTo,
            persons: [person].asHasMany)
        .init(repo);

    var obj = repo.serialize(family);
    expect(obj, isA<Map<String, dynamic>>());
    expect(obj, {
      'id': '1',
      'surname': "Smith",
      'house': house.key,
      'persons': [person.key],
      'dogs': null
    });
  });

  test('deserialize with relationships', () {
    var repo = injection.locator<Repository<Family>>();

    final houseRepo = injection.locator<Repository<House>>();
    final personRepo = injection.locator<Repository<Person>>();

    final house = House(id: "1", address: "123 Main St").init(houseRepo);
    final person = Person(id: "1", name: "John", age: 21).init(personRepo);

    var obj = {
      'id': '1',
      'surname': "Smith",
      'house': house.key,
      'persons': [person.key]
    };

    var family = repo.deserialize(obj);

    expect(family.isNew, false); // also checks if the model was init'd
    expect(family, Family(id: "1", surname: "Smith"));
    expect(family.house.value.address, "123 Main St");
    expect(family.persons.first.age, 21);
  });

  test('create and save locally', () async {
    var repo = injection.locator<Repository<House>>();
    var house = House(address: "12 Lincoln Rd").init(repo);
    expect(repo.localAdapter.findOne(house.key), house);
  });

  test('watchAll', () async {
    var repo = injection.locator<Repository<Person>>();
    // make sure there are no items in local storage from previous tests
    await repo.localAdapter.clear();

    expect(repo.localAdapter.keys.length, 0);

    var stream = StreamQueue(repo.watchAll(remote: false).stream);
    (repo as PersonPollAdapter).generatePeople();

    final matcher = predicate((p) {
      return p is Person && p.name.startsWith('zzz-') && p.age < 89;
    });

    expect(stream, mayEmitMultiple(isEmpty));

    await expectLater(
      stream,
      emitsInOrder([
        [matcher],
        [matcher, matcher],
        [matcher, matcher, matcher]
      ]),
    );

    expect(repo.localAdapter.keys.length, 3);
  });

  // test('ensure there is never more than the amount of real IDs', () async {
  //   var repo = injection.locator<Repository<Person>>();
  //   // make sure there are no items in local storage from previous tests
  //   await repo.localAdapter.clear();

  //   expect(repo.localAdapter.keys.length, 0);

  //   var stream = StreamQueue(repo.watchAll(remote: false).stream);

  //   var matcherMaxLength =
  //       (int length) => predicate((List<Person> s) => s.length <= length);

  //   // ignore: unawaited_futures
  //   (() async {
  //     for (int i = 0; i < 15; i++) {
  //       // wait for debounce with some margin
  //       await Future.delayed(Duration(milliseconds: 50));
  //       List.generate(28, (_) => Person.generateRandom(repo, withId: true));
  //     }
  //   })();

  //   // ignore empty
  //   expect(stream, mayEmitMultiple(isEmpty));

  //   await expectLater(
  //     stream,
  //     emitsInOrder([
  //       matcherMaxLength(28),
  //       matcherMaxLength(56),
  //       matcherMaxLength(84),
  //       matcherMaxLength(84),
  //       matcherMaxLength(84),
  //       matcherMaxLength(84),
  //       matcherMaxLength(84),
  //       matcherMaxLength(84),
  //       matcherMaxLength(84),
  //       matcherMaxLength(84),
  //       matcherMaxLength(84),
  //       matcherMaxLength(84),
  //       matcherMaxLength(84),
  //       matcherMaxLength(84),
  //       matcherMaxLength(84),
  //     ]),
  //   );
  // });
}
