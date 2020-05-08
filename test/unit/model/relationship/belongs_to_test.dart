import 'package:flutter_data/flutter_data.dart';
import 'package:test/test.dart';

import '../../../models/family.dart';
import '../../../models/house.dart';
import '../../../models/person.dart';
import '../../setup.dart';

void main() async {
  setUpAll(setUpAllFn);
  tearDownAll(tearDownAllFn);

  test('constructor', () {
    var manager = injection.locator<DataManager>();
    var rel = BelongsTo<Person>(null, manager);
    expect(rel.dataId, isNull);
    rel = BelongsTo<Person>(Person(id: '1', name: 'zzz', age: 7), manager);
    expect(rel.dataId, manager.dataId<Person>('1'));
  });

  test('deserialize with included BelongsTo', () async {
    // exceptionally uses this repo so we can supply included models
    var repo = injection.locator<FamilyRepositoryWithStandardJSONAdapter>();
    var houseRepo = injection.locator<Repository<House>>();

    var house = {'id': '432337', 'address': 'Ozark Lake, MO'};
    var familyJson = {'surname': 'Byrde', 'house': house};
    repo.deserialize(familyJson);

    expect(await houseRepo.findOne('432337'),
        predicate((p) => p.address == 'Ozark Lake, MO'));
  });

  test('fromJson', () {
    var repo = injection.locator<Repository<Person>>();
    var manager = repo.manager;

    var rel = BelongsTo<Person>.fromJson({
      '_': [manager.dataId<Person>('1').key, manager]
    });
    var person = Person(id: '1', name: 'zzz', age: 7);
    repo.save(person);

    expect(rel, BelongsTo<Person>(person, manager));
    expect(rel.dataId, manager.dataId<Person>('1'));
    expect(rel.value, person);
  });

  test('re-assign belongsto in mutable model', () {
    var familyRepo = injection.locator<Repository<Family>>();
    var personRepo = injection.locator<Repository<Person>>();

    var family = Family(surname: 'Toraine').init(familyRepo);
    var person = Person(name: 'Claire', age: 31).init(personRepo);
    person.family = BelongsTo<Family>(family, familyRepo.manager);
    expect(person.family.dataId.key, family.key);
    expect(person.family.debugOwner, isNull);
    personRepo.syncRelationships(person);
    expect(person.family.debugOwner, isNotNull);
  });

  test('set owner in relationships', () {
    var adapter = injection.locator<Repository<Family>>();
    var person = Person(id: '1', name: 'John', age: 37);
    var house = House(id: '31', address: '123 Main St');
    var family = Family(
        id: '1',
        surname: 'Smith',
        house: BelongsTo<House>(house),
        persons: HasMany<Person>({person}));

    // no dataId associated to family or relationships
    expect(family.house.dataId, isNull);
    expect(family.persons.dataIds, isEmpty);

    adapter.setOwnerInRelationships(
        adapter.manager.dataId<Family>('1'), family);

    // relationships are now associated to a dataId
    expect(family.house.dataId, adapter.manager.dataId<House>('31'));
    expect(family.persons.dataIds.first, adapter.manager.dataId<Person>('1'));
  });

  test('watch', () {
    var repository = injection.locator<Repository<Family>>();
    var family = Family(
      id: '1',
      surname: 'Smith',
      house: BelongsTo<House>(),
    ).init(repository);

    var notifier = family.house.watch();
    for (var i = 0; i < 3; i++) {
      if (i == 1) family.house.value = House(id: '31', address: '123 Main St');
      if (i == 2) family.house.value = null;
      notifier.addListener((state) {
        if (i == 0) expect(state.model, null);
        if (i == 1) expect(state.model, family.house.value);
        if (i == 2) expect(state.model, null);
      });
    }
  });
}
