import 'package:flutter_data/flutter_data.dart';
import 'package:test/test.dart';

import 'models/family.dart';
import 'models/house.dart';
import 'models/person.dart';
import 'setup.dart';

void main() async {
  setUpAll(setUpAllFn);
  tearDownAll(tearDownAllFn);

  test('serialize', () {
    var manager = injection.locator<DataManager>();

    var person = Person(id: '1', name: "Franco", age: 28);
    var personRel = HasMany<Person>([person], manager);
    var house = House(id: '1', address: "123 Main St");
    var houseRel = BelongsTo<House>(house, manager);

    var family =
        Family(id: "1", surname: "Smith", house: houseRel, persons: personRel);

    var map = injection.locator<LocalAdapter<Family>>().serialize(family);
    expect(map, {
      'id': "1",
      'surname': "Smith",
      'house': houseRel.key,
      'persons': personRel.keys
    });
  });

  test('internalLocalDeserialize', () {
    var manager = injection.locator<DataManager>();

    var person = Person(id: '1', name: "Franco", age: 28);
    var personRel = HasMany<Person>([person], manager);
    var house = House(id: '1', address: "123 Main St");
    var houseRel = BelongsTo<House>(house, manager);

    var map = {
      'id': "1",
      'surname': "Smith",
      'house': houseRel.key,
      'persons': personRel.keys
    };

    var family =
        injection.locator<LocalAdapter<Family>>().internalLocalDeserialize(map);
    expect(family,
        Family(id: "1", surname: "Smith", house: houseRel, persons: personRel));
  });

  test('typeId', () {
    expect(injection.locator<LocalAdapter<Family>>().typeId, isNotNull);
  });

  test('findAll', () {
    var adapter = injection.locator<LocalAdapter<Family>>();
    var family1 = Family(id: "1", surname: "Smith");
    var family2 = Family(id: "2", surname: "Jones");

    adapter.box.put('families#1', family1);
    adapter.box.put('families#2', family2);
    var families = adapter.findAll();

    expect(families, [family1, family2]);
  });

  test('findOne', () {
    var adapter = injection.locator<LocalAdapter<Family>>();
    var family1 = Family(id: "1", surname: "Smith");

    adapter.box.put('families#1', family1);
    var family = adapter.findOne('families#1');

    expect(family, family1);
  });

  test('fixMap', () {
    var before = {
      'person': <dynamic, dynamic>{'age': 32}
    };
    var after = injection.locator<LocalAdapter<Person>>().fixMap(before);

    expect(after['person'], isA<Map<String, dynamic>>());
  });
}
