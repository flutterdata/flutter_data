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
    var repo = injection.locator<Repository<Person>>();
    var person = Person(id: '1', name: "zzz", age: 7).init(repo);

    var rel = HasMany<Person>([], manager);
    expect(rel.length, 0);

    rel = HasMany<Person>([person], manager);
    expect(rel.first.dataId, manager.dataId<Person>('1'));
  });

  // test('fromToMany with included', () async {
  //   var repo = injection.locator<Repository<Person>>();
  //   var manager = repo.manager;

  //   var sue = {'id': '71', 'name': "Sue", 'age': 74};
  //   var helen = {'id': '72', 'name': "Helen", 'age': 59};

  //   HasMany<Person>.fromJson({
  //     '_': [
  //       [manager.dataId<Person>('72').key],
  //       manager
  //     ]
  //   });

  //   // included: [sue, helen],

  //   // helen should be saved (cause it was in included)
  //   expect(await repo.findOne(helen.id, remote: false), isNotNull);

  //   // but sue shouldn't, as it wasn't referenced in any relationship
  //   expect(await repo.findOne(sue.id, remote: false), isNull);
  // });

  test('fromJson', () {
    var repo = injection.locator<Repository<Person>>();
    var manager = repo.manager;

    var rel = HasMany<Person>.fromJson({
      '_': [
        [manager.dataId<Person>('1').key],
        manager
      ]
    });
    var person = Person(id: '1', name: "zzz", age: 7).init(repo);

    expect(rel, HasMany<Person>([person], manager));
    expect(rel.first, person);
    expect(rel.first.dataId, manager.dataId<Person>('1'));
  });

  test('re-assign hasmany in mutable model', () {
    var familyRepo = injection.locator<Repository<Family>>();
    var personRepo = injection.locator<Repository<Person>>();

    var family = Family(surname: "Toraine").init(familyRepo);
    var person = Person(name: "Claire", age: 31).init(personRepo);
    family.persons = HasMany<Person>([person], personRepo.manager);

    expect(family.persons.first.dataId, person.dataId);
    expect(family.persons.debugOwner, isNull);
    family.init(familyRepo);
    expect(family.persons.debugOwner, isNotNull);
  });
}
