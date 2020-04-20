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
    var person = Person(id: '1', name: 'zzz', age: 7).init(repo);

    var rel = HasMany<Person>([], manager);
    expect(rel.length, 0);

    rel = HasMany<Person>([person], manager);
    expect(rel.first.key, manager.dataId<Person>('1').key);
  });

  test('deserialize with included', () {
    // exceptionally uses this repo so we can supply included models
    var repo = injection.locator<FamilyRepositoryWithStandardJSONAdapter>();
    var adapter = injection.locator<Repository<Person>>().localAdapter;
    var manager = repo.manager;

    var marty = {'id': '71', 'name': 'Marty', 'age': 52};
    var wendy = {'id': '72', 'name': 'Wendy', 'age': 54};

    var familyJson = {
      'surname': 'Byrde',
      'persons': [marty, wendy]
    };

    repo.deserialize(familyJson);

    expect(adapter.findOne(DataId<Person>('71', manager).key), isNotNull);
    expect(adapter.findOne(DataId<Person>('72', manager).key), isNotNull);
  });

  test('fromJson', () {
    var repo = injection.locator<Repository<Person>>();
    var manager = repo.manager;

    var rel = HasMany<Person>.fromJson({
      '_': [
        [manager.dataId<Person>('1').key],
        manager
      ]
    });
    var person = Person(id: '1', name: 'zzz', age: 7).init(repo);

    expect(rel, HasMany<Person>([person], manager));
    expect(rel.first, person);
    expect(rel.first.key, manager.dataId<Person>('1').key);
  });

  test('re-assign hasmany in mutable model', () {
    var familyRepo = injection.locator<Repository<Family>>();
    var personRepo = injection.locator<Repository<Person>>();

    var family = Family(surname: 'Toraine').init(familyRepo);
    var person = Person(name: 'Claire', age: 31).init(personRepo);
    family.persons = HasMany<Person>([person], personRepo.manager);

    expect(family.persons.first.key, person.key);
    expect(family.persons.debugOwner, isNull);
    familyRepo.syncRelationships(family);
    expect(family.persons.debugOwner, isNotNull);
  });
}
