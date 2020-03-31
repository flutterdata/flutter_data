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

  test('constructor', () {
    var manager = injection.locator<DataManager>();
    var rel = BelongsTo<Person>(null, manager);
    expect(rel.dataId, isNull);
    rel = BelongsTo<Person>(Person(id: '1', name: "zzz", age: 7), manager);
    expect(rel.dataId, DataId<Person>('1', manager));
  });

  test('fromJson + equality', () {
    var manager = injection.locator<DataManager>();
    var p = Person(id: '1', name: "zzz", age: 7);
    expect(
        BelongsTo<Person>.fromJson(
            {'BelongsTo': BelongsTo<Person>(p, manager)}),
        BelongsTo<Person>(p, manager));
  });

  test('fromToOne with included', () {
    var adapter = injection.locator<Repository<Person>>().localAdapter;
    var manager = adapter.manager;
    var r1 =
        ResourceObject('people', '1', attributes: {'name': "r1", 'age': 17});
    var r2 =
        ResourceObject('people', '2', attributes: {'name': "r2", 'age': 27});

    var rel = BelongsTo<Person>.fromToOne(
        ToOne(DataId<Person>('1', manager)), manager,
        included: [r1, r2]);

    expect(rel.dataId, DataId<Person>("1", manager));
    expect(adapter.findOne(rel.dataId.key), isNotNull);
    expect(adapter.findOne(rel.dataId.key).dataId,
        isNotNull); // manager should be set
    expect(adapter.findOne(DataId<Person>('2', manager).key), isNull);
  });

  test('fromKey', () {
    var adapter = injection.locator<Repository<Person>>().localAdapter;
    var manager = adapter.manager;
    var rel = BelongsTo<Person>.fromKey(
      DataId<Person>('1', manager),
      manager,
    );
    var person = Person(id: '1', name: "zzz", age: 7);
    adapter.save(rel.dataId.key, person);

    expect(rel.dataId, DataId<Person>("1", manager));
    expect(rel.value, person);
  });

  test('relationship scenario #1', () {
    var repo = injection.locator<Repository<Family>>();
    var manager = repo.localAdapter.manager;
    var personRepo = injection.locator<Repository<Person>>();
    var houseRepo = injection.locator<Repository<House>>();

    // (1) first load family (with relationships)
    var personDataIds = [
      DataId<Person>('1', manager),
      DataId<Person>('2', manager),
      DataId<Person>('3', manager)
    ];
    var houseDataId = DataId<House>('98', manager);
    var family = Family(
      id: "1",
      surname: "Jones",
      persons: HasMany<Person>.fromToMany(ToMany(personDataIds), manager),
      house: BelongsTo.fromToOne(ToOne(houseDataId), manager),
    ).createFrom(repo);

    // (2) then load persons
    Person(id: '1', name: 'z1', age: 23)
        .createFrom(personRepo)
        .save(remote: false);
    Person(id: '2', name: 'z2', age: 33)
        .createFrom(personRepo)
        .save(remote: false);

    // (3) assert two first are linked, third one null, house is null
    expect(family.persons[0], isNotNull);
    expect(family.persons[1], isNotNull);
    expect(family.persons[2], isNull);
    expect(family.house.value, isNull);

    // (4) load the last person and assert it exists now
    Person(id: '3', name: 'z3', age: 3)
        .createFrom(personRepo)
        .save(remote: false);
    var house =
        House(id: '98', address: "21 Coconut Trail").createFrom(houseRepo);

    expect(family.persons[2].age, 3);
    expect(family.house.value.address, endsWith('Trail'));

    // (5) TO-DO
    expect(house.families.length, 0);
  });
}
