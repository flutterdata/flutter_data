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
    var repo = injection.locator<Repository<Family>>();
    var person = Person(id: '1', name: 'John', age: 37);
    var house = House(id: '31', address: '123 Main St');
    var house2 = House(id: '2', address: '456 Main St');

    var family = Family(
        id: '1',
        surname: 'Smith',
        residence: BelongsTo<House>(house),
        persons: HasMany<Person>({person}));

    // no dataId associated to family or relationships
    expect(family.residence.key, isNull);
    expect(family.persons.keys, isEmpty);

    family.init(repo);

    // relationships are now associated to a key
    expect(family.residence.key, repo.manager.getKeyForId('houses', '31'));
    expect(family.persons.keys.first, repo.manager.getKeyForId('people', '1'));

    // ensure there are not more than 1 key
    family.residence.value = house2;
    expect(family.residence.keys, hasLength(1));
  });

  test('watch', () async {
    final repository = injection.locator<Repository<Family>>();
    final family = Family(
      id: '1',
      surname: 'Smith',
      residence: BelongsTo<House>(),
    ).init(repository);

    final notifier = family.residence.watch();

    var i = 0;
    notifier.addListener(
      expectAsync1((house) {
        if (i == 0) expect(house.address, startsWith('456'));
        if (i == 1) expect(house.address, startsWith('123'));
        if (i == 2) expect(house, isNull);
        i++;
      }, count: 3),
      fireImmediately: false,
    );

    family.residence.value = House(id: '2', address: '456 Main St');
    family.residence.value = House(id: '1', address: '123 Main St');
    family.residence.value = null;
  });
}
