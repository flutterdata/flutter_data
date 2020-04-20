import 'package:flutter_data/flutter_data.dart';
import 'package:test/test.dart';

import 'models/family.dart';
import 'models/house.dart';
import 'models/person.dart';
import 'setup.dart';

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

  test('deserialize with included', () {
    // exceptionally uses this repo so we can supply included models
    var repo = injection.locator<FamilyRepositoryWithStandardJSONAdapter>();
    var adapter = injection.locator<Repository<House>>().localAdapter;
    var manager = repo.manager;

    var house = {'id': '432337', 'address': 'Ozark Lake, MO'};
    var familyJson = {'surname': 'Byrde', 'house': house};
    repo.deserialize(familyJson);

    expect(adapter.findOne(DataId<House>('432337', manager).key), isNotNull);
  });

  test('fromJson', () {
    var adapter = injection.locator<Repository<Person>>().localAdapter;
    var manager = adapter.manager;

    var rel = BelongsTo<Person>.fromJson({
      '_': [manager.dataId<Person>('1').key, manager]
    });
    var person = Person(id: '1', name: 'zzz', age: 7);
    adapter.save(rel.dataId.key, person);

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
}
