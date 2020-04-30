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

    var family = Family(id: '55', surname: 'Kelley');
    var model =
        Person(id: '1', name: 'John', age: 27, family: family.asBelongsTo)
            .init(repo);

    // (1) it wires up the relationship (setOwnerInRelationship)
    expect(model.family.key, manager.dataId<Family>('55').key);

    // (2) it saves the model locally
    expect(model, repo.localAdapter.findOne(model.key));
  });

  test('locator', () {
    var repo = injection.locator<Repository<Person>>();
    expect(repo.manager.locator, isNotNull);
  });

  test('serialize with relationships', () {
    var repo = injection.locator<Repository<Family>>();

    var person = Person(id: '1', name: 'John', age: 37);
    var house = House(id: '1', address: '123 Main St');
    var family = Family(
            id: '1',
            surname: 'Smith',
            house: house.asBelongsTo,
            persons: [person].asHasMany)
        .init(repo);

    var obj = repo.serialize(family);
    expect(obj, isA<Map<String, dynamic>>());
    expect(obj, {
      'id': '1',
      'surname': 'Smith',
      'house': house.key,
      'persons': [person.key],
      'dogs': null
    });
  });

  test('deserialize existing', () {
    var repo = injection.locator<Repository<Family>>();
    repo.localAdapter.clear();
    expect(repo.localAdapter.keys, []);
    var family = Family(surname: 'Moletto').init(repo);

    // simulate "save"
    var obj = {
      'id': '1098',
      'surname': 'Moletto',
    };
    var family2 = repo.deserialize(obj, key: family.key);

    expect(family2.isNew, false); // also checks if the model was init'd
    expect(family2, Family(id: '1098', surname: 'Moletto'));
    expect(repo.localAdapter.keys, [family2.key]);
  });

  test('deserialize existing without initializing', () {
    var repo = injection.locator<Repository<Family>>();
    var obj = {
      'id': '3098',
      'surname': 'Moletto',
    };
    var family2 = repo.deserialize(obj, initialize: false);
    expect(family2.key, isNull);
    family2.init(repo);
    expect(family2.key, isNotNull);
  });

  test('deserialize many local for same remote ID', () {
    var repo = injection.locator<Repository<Family>>();
    repo.localAdapter.clear();
    expect(repo.localAdapter.keys, []);
    var family = Family(surname: 'Moletto').init(repo);
    var family2 = Family(surname: 'Zandiver').init(repo);

    // simulate "save" for family
    var obj = {
      'id': '1298',
      'surname': 'Helsinki',
    };
    var family1b = repo.deserialize(obj, key: family.key);

    // simulate "save" for family2
    var obj2 = {
      'id': '1298',
      'surname': 'Oslo',
    };
    var family2b = repo.deserialize(obj2, key: family2.key);

    // since obj returned with same ID - only one key is left
    expect(family1b.key, family2b.key);
    expect(repo.localAdapter.keys, [family.key]);
  });

  test('returning a different remote ID for a requested ID is not supported',
      () {
    var repo = injection.locator<Repository<Family>>();
    repo.localAdapter.clear();
    expect(repo.localAdapter.keys, []);
    var family0 = Family(id: '2908', surname: 'Moletto').init(repo);

    // simulate a "findOne" with some id
    var family = Family(id: '2905', surname: 'Moletto').init(repo);
    var obj2 = {
      'id': '2908', // that returns a different ID (already in the system)
      'surname': 'Oslo',
    };
    var family2 = repo.deserialize(obj2, key: family.key);

    // even though we supplied family.key, it will be different (family0's)
    expect(family2.key, isNot(family.key));
    expect(repo.localAdapter.keys, [family0.key]);
  });

  test('remote ID can be replaced with public methods', () {
    var repo = injection.locator<Repository<Family>>();
    repo.localAdapter.clear();
    expect(repo.localAdapter.keys, []);
    Family(id: '2908', surname: 'Moletto').init(repo);
    // app is now ready and loaded one family from local storage

    // simulate a "findOne" with some id
    var family = Family(id: '2905', surname: 'Moletto').init(repo);
    var originalKey = family.key;
    var obj2 = {
      'id': '2908', // that returns a different ID (already in the system)
      'surname': 'Oslo',
    };
    var family2 = repo.deserialize(obj2, key: family.key);

    // expect family to have been deleted by init, family2 remains
    expect(repo.localAdapter.keys, [family2.key]);
    expect(repo.manager.keysBox.keys, isNot(contains('families#${family.id}')));
    expect(repo.manager.keysBox.keys, contains('families#${family2.id}'));

    // delete family2 and its key
    repo.delete(family2.id, remote: false);

    // expect no keys remain
    expect(repo.localAdapter.keys, isEmpty);
    expect(repo.manager.keysBox.keys, isNot(contains('families#${family.id}')));
    expect(
        repo.manager.keysBox.keys, isNot(contains('families#${family2.id}')));

    // associate new id to original existing key
    family2.init(repo, key: originalKey, save: true);

    // original key should now be associated to the deserialized model
    expect(repo.manager.keysBox.get('families#${family2.id}'), originalKey);
    expect(repo.localAdapter.keys, [originalKey]);
    expect(repo.localAdapter.findOne(originalKey), family2);
  });

  test('deserialize with relationships', () {
    var repo = injection.locator<Repository<Family>>();

    final houseRepo = injection.locator<Repository<House>>();
    final personRepo = injection.locator<Repository<Person>>();

    final house = House(id: '1', address: '123 Main St').init(houseRepo);
    final person = Person(id: '1', name: 'John', age: 21).init(personRepo);

    var obj = {
      'id': '1',
      'surname': 'Smith',
      'house': house.key,
      'persons': [person.key]
    };

    var family = repo.deserialize(obj);

    expect(family.isNew, false); // also checks if the model was init'd
    expect(family, Family(id: '1', surname: 'Smith'));
    expect(family.house.value.address, '123 Main St');
    expect(family.persons.first.age, 21);
  });

  test('delete', () async {
    final repo = injection.locator<Repository<Person>>();
    final person = Person(id: '1', name: 'John', age: 21).init(repo);
    await repo.delete(person.id, remote: false);
    var p2 = repo.localAdapter.findOne(person.key);
    expect(p2, isNull);
    expect(repo.manager.keysBox.get('people#${person.id}'), isNull);
  });

  test('create and save locally', () async {
    var repo = injection.locator<Repository<House>>();
    var house = House(address: '12 Lincoln Rd').init(repo);
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
