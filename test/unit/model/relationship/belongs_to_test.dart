import 'package:flutter_data/flutter_data.dart';
import 'package:test/test.dart';

import '../../../models/family.dart';
import '../../../models/house.dart';
import '../../../models/person.dart';
import '../../setup.dart';

void main() async {
  setUpAll(setUpAllFn);
  tearDownAll(tearDownAllFn);

  test('deserialize with included BelongsTo', () async {
    // exceptionally uses this repo so we can supply included models
    var repo = injection.locator<FamilyRepositoryWithStandardJSONAdapter>();
    var houseRepo = injection.locator<Repository<House>>();

    var house = {'id': '432337', 'address': 'Ozark Lake, MO'};
    var familyJson = {'surname': 'Byrde', 'residence': house};
    repo.deserialize(familyJson);

    expect(await houseRepo.findOne('432337'),
        predicate((p) => p.address == 'Ozark Lake, MO'));
  });

  test('set owner in relationships', () {
    final repo = injection.locator<Repository<Family>>();

    var person = Person(id: '1', name: 'John', age: 37).init(manager);
    var house = House(id: '31', address: '123 Main St').init(manager);
    var house2 = House(id: '2', address: '456 Main St').init(manager);

    var family = Family(
        id: '1',
        surname: 'Smith',
        residence: BelongsTo<House>(house),
        persons: HasMany<Person>({person}));

    // no dataId associated to family or relationships
    expect(family.residence.key, isNull);
    expect(family.persons.keys, isEmpty);

    family.init(manager);

    // relationships are now associated to a key
    expect(family.residence.key, repo.manager.getKeyForId('houses', '31'));
    expect(family.persons.keys.first, repo.manager.getKeyForId('people', '1'));

    // ensure there are not more than 1 key
    family.residence.value = house2;
    expect(family.residence.keys, hasLength(1));
  });

  test('watch', () async {
    final family = Family(
      id: '22',
      surname: 'Besson',
      residence: BelongsTo<House>(),
    ).init(manager);

    final notifier = family.residence.watch();

    var i = 0;
    notifier.addListener(
      expectAsync1((house) {
        if (i == 0) expect(house.address, startsWith('456'));
        // we expect a null here, as replacing a value in a Set
        // implies removing & adding
        // this shouldn't be a problem in production with throttling
        if (i == 1) expect(house, isNull);
        if (i == 2) expect(house.address, startsWith('123'));
        if (i == 3) expect(house, isNull);
        i++;
      }, count: 4),
      fireImmediately: false,
    );

    family.residence.value =
        House(id: '2', address: '456 Main St').init(manager);
    family.residence.value =
        House(id: '1', address: '123 Main St').init(manager);
    family.residence.value = null;
  });
}
