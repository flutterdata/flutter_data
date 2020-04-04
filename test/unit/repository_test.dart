import 'package:flutter_data/flutter_data.dart';
import 'package:json_api/document.dart';
import 'package:test/test.dart';

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

    // (1) it sets the manager in both model and relationship
    // DataSupport#_manager needs to remain private
    // so that's compatible with freezed
    // but it's equivalent to checking on dataId's
    expect(model.dataId.manager, equals(manager));
    expect(family.dataId.manager, equals(manager));

    // (2) it wires up the relationship (setOwnerInRelationship)
    expect(model.family.key, manager.dataId<Family>("55").key);

    // (3) it saves the model locally
    expect(model, repo.localAdapter.box.get(model.key));
  });

  test('locator', () {
    var repo = injection.locator<Repository<Person>>();
    expect(repo.locator, isNotNull);
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
      'house': family.house.value.key,
      'persons': family.persons.keys
    });
  });

  test('deserialize with relationships', () {
    var repo = injection.locator<Repository<Family>>();

    injection
        .locator<Repository<House>>()
        .localAdapter
        .save('h1', House(id: "1", address: "123 Main St"));
    injection
        .locator<Repository<Person>>()
        .localAdapter
        .save('p1', Person(id: "1", name: "John", age: 21));

    var obj = {
      'surname': "Smith",
      'house': 'h1',
      'persons': ['p1']
    };

    var family = repo.deserialize(obj);

    expect(family, Family(id: "1", surname: "Smith"));
    expect(family.house.value.address, "123 Main St");
    expect(family.persons.first.age, 21);
  });

  test('set owner in relationships', () {
    var repo = injection.locator<Repository<Family>>();

    var person = Person(id: '1', name: "John", age: 37);
    var house = House(id: '31', address: "123 Main St");
    var family = Family(
        id: "1",
        surname: "Smith",
        house: BelongsTo<House>(house),
        persons: HasMany<Person>([person]));

    // no manager associated to family or relationships
    expect(family.house.dataId.manager, isNull);
    expect(family.persons.dataIds.first.manager, isNull);

    repo.setOwnerInRelationships(repo.manager.dataId<Family>("1"), family);

    // relationships are now associated to a manager
    expect(family.house.dataId, repo.manager.dataId<House>("31"));
    expect(family.persons.dataIds.first, repo.manager.dataId<Person>("1"));
  });

  test('create and save locally', () async {
    var repo = injection.locator<Repository<House>>();
    var house = House(address: "12 Lincoln Rd").init(repo);
    expect(house, await house.save(remote: false));
  });
}
