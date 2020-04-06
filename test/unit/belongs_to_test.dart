import 'package:flutter_data/flutter_data.dart';
import 'package:test/test.dart';

import 'models/family.dart';
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
    expect(rel.dataId, manager.dataId<Person>('1'));
  });

  // test('fromToOne with included', () {
  //   var adapter = injection.locator<Repository<Person>>().localAdapter;
  //   var manager = adapter.manager;
  //   var r1 = {'id': '1', 'name': "r1", 'age': 17};
  //   var r2 = {'id': '2', 'name': "r2", 'age': 27};

  //   var rel = BelongsTo<Person>.fromJson({
  //     '_': [manager.dataId<Person>('1').key, manager]
  //   });

  //   expect(rel.dataId, manager.dataId<Person>("1"));
  //   // person 1 should be saved (cause it was in included)
  //   expect(adapter.findOne(rel.dataId.key), isNotNull);
  //   expect(adapter.findOne(rel.dataId.key).dataId,
  //       isNotNull); // manager should be set
  //   // but person 2 shouldn't, as it wasn't referenced in any relationship
  //   expect(adapter.findOne(manager.dataId<Person>('2').key), isNull);
  // });

  test('fromJson', () {
    var adapter = injection.locator<Repository<Person>>().localAdapter;
    var manager = adapter.manager;

    var rel = BelongsTo<Person>.fromJson({
      '_': [manager.dataId<Person>('1').key, manager]
    });
    var person = Person(id: '1', name: "zzz", age: 7);
    adapter.save(rel.dataId.key, person);

    expect(rel, BelongsTo<Person>(person, manager));
    expect(rel.dataId, manager.dataId<Person>("1"));
    expect(rel.value, person);
  });

  test('re-assign belongsto in mutable model', () {
    var familyRepo = injection.locator<Repository<Family>>();
    var personRepo = injection.locator<Repository<Person>>();

    var family = Family(surname: "Toraine").init(familyRepo);
    var person = Person(name: "Claire", age: 31).init(personRepo);
    person.family = BelongsTo<Family>(family, familyRepo.manager);
    expect(person.family.dataId, family.dataId);
    expect(person.family.debugOwner, isNull);
    person.init(personRepo);
    expect(person.family.debugOwner, isNotNull);
  });
}
