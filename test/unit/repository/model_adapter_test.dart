import 'package:flutter_data/flutter_data.dart';
import 'package:test/test.dart';

import '../../models/family.dart';
import '../../models/house.dart';
import '../../models/person.dart';
import '../setup.dart';

void main() async {
  setUpAll(setUpAllFn);
  tearDownAll(tearDownAllFn);

  // serialization tests

  test('serialize', () {
    var manager = injection.locator<DataManager>();

    var person = Person(id: '1', name: 'Franco', age: 28);
    var personRel = HasMany<Person>({person}, manager);
    var house = House(id: '1', address: '123 Main St');
    var houseRel = BelongsTo<House>(house, manager);

    var family =
        Family(id: '1', surname: 'Smith', house: houseRel, persons: personRel);

    var map = injection.locator<Repository<Family>>().serialize(family);
    expect(map, {
      'id': '1',
      'surname': 'Smith',
      'house': houseRel.key,
      'persons': personRel.keys,
      'dogs': null
    });
  });

  test('serialize with relationships', () {
    var repo = injection.locator<Repository<Family>>();

    var person = Person(id: '1', name: 'John', age: 37);
    var house = House(id: '1', address: '123 Main St');
    var family = Family(
            id: '1',
            surname: 'Smith',
            house: house.asBelongsTo,
            persons: {person}.asHasMany)
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

  test('deserialize', () {
    var manager = injection.locator<DataManager>();

    var person = Person(id: '1', name: 'Franco', age: 28);
    var personRel = HasMany<Person>({person}, manager);
    var house = House(id: '1', address: '123 Main St');
    var houseRel = BelongsTo<House>(house, manager);

    var map = {
      'id': '1',
      'surname': 'Smith',
      'house': houseRel.key,
      'persons': personRel.keys
    };

    var family = injection.locator<Repository<Family>>().deserialize(map);
    expect(family,
        Family(id: '1', surname: 'Smith', house: houseRel, persons: personRel));
  });

  test('deserialize existing', () {
    var repo = injection.locator<Repository<Family>>();
    repo.box.clear();
    expect(repo.box.keys, isEmpty);
    var family = Family(surname: 'Moletto').init(repo);

    // simulate "save"
    var obj = {
      'id': '1098',
      'surname': 'Moletto',
    };
    var family2 = repo.deserialize(obj, key: family.key);

    expect(family2.isNew, false); // also checks if the model was init'd
    expect(family2, Family(id: '1098', surname: 'Moletto'));
    expect(repo.box.keys, [family2.key]);
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
    repo.box.clear();
    expect(repo.box.keys, isEmpty);
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
    expect(repo.box.keys, [family.key]);
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
}
