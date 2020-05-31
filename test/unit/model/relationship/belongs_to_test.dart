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
  });

  // test('watch', () {
  //   var repository = injection.locator<Repository<Family>>();
  //   var family = Family(
  //     id: '1',
  //     surname: 'Smith',
  //     residence: BelongsTo<House>(),
  //   ).init(repository);

  //   var notifier = family.residence.watch();
  //   for (var i = 0; i < 3; i++) {
  //     if (i == 1) {
  //       family.residence.value = House(id: '31', address: '123 Main St');
  //     }
  //     if (i == 2) {
  //       family.residence.value = null;
  //     }
  //     var dispose = notifier.addListener((state) {
  //       if (i == 0) expect(state.model, null);
  //       if (i == 1) expect(state.model, family.residence.value);
  //       if (i == 2) expect(state.model, null);
  //     });
  //     dispose();
  //   }
  // });
}
