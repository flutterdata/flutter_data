import 'package:flutter_data/flutter_data.dart';
import 'package:test/test.dart';

import '../../../models/family.dart';
import '../../../models/person.dart';
import '../../setup.dart';

void main() async {
  setUpAll(setUpAllFn);
  tearDownAll(tearDownAllFn);

  test('constructor', () {
    var manager = injection.locator<DataManager>();
    var repo = injection.locator<Repository<Person>>();
    var person = Person(id: '1', name: 'zzz', age: 7).init(repo);

    var rel = HasMany<Person>({}, manager);
    expect(rel.length, 0);

    rel = HasMany<Person>({person}, manager);
    expect(rel.first.key, manager.dataId<Person>('1').key);
  });

  test('HasMany is a Set', () {
    final persons = HasMany<Person>();
    var person = Person(name: 'zzz', age: 22);
    persons.add(person);
    persons.add(person);
    persons.add(person);
    persons.add(person);
    expect(persons.length, 1);
    expect(persons.lookup(person), person);

    persons.manager = injection.locator<DataManager>();
    persons.initializeModels();
    final person2 = Person(name: 'zzz2', age: 2);
    persons.add(person2);
    expect(persons.length, 2);

    persons.remove(person);
    expect(persons.length, 1);
    expect(persons.lookup(person2), person2);

    persons.clear();
    expect(persons.length, 0);
  });

  test('deserialize with included HasMany', () async {
    // exceptionally uses this repo so we can supply included models
    var repo = injection.locator<FamilyRepositoryWithStandardJSONAdapter>();
    var personRepo = injection.locator<Repository<Person>>();

    var marty = {'id': '71', 'name': 'Marty', 'age': 52};
    var wendy = {'id': '72', 'name': 'Wendy', 'age': 54};

    var familyJson = {
      'surname': 'Byrde',
      'persons': [marty, wendy]
    };

    repo.deserialize(familyJson);

    expect(await personRepo.findOne('71'), predicate((p) => p.id == '71'));
    expect(await personRepo.findOne('72'), predicate((p) => p.age == 54));
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

    expect(rel, HasMany<Person>({person}, manager));
    expect(rel.first, person);
    expect(rel.first.key, manager.dataId<Person>('1').key);
  });

  test('re-assign hasmany in mutable model', () {
    var familyRepo = injection.locator<Repository<Family>>();
    var personRepo = injection.locator<Repository<Person>>();

    var family = Family(surname: 'Toraine').init(familyRepo);
    var person = Person(name: 'Claire', age: 31).init(personRepo);
    family.persons = HasMany<Person>({person}, personRepo.manager);

    expect(family.persons.first.key, person.key);
    expect(family.persons.debugOwner, isNull);
    familyRepo.syncRelationships(family);
    expect(family.persons.debugOwner, isNotNull);
  });

  test('does not contain nulls', () {
    var repo = injection.locator<Repository<Person>>();
    var person = Person(name: 'Claire', age: 31).init(repo);
    var rel = HasMany<Person>({person}, repo.manager);

    rel.add(null);
    expect(rel, {person});

    rel.dataIds.add(null);
    expect(rel.toSet(), {person});
  });

  test('watch', () {
    var repository = injection.locator<Repository<Family>>();
    var family = Family(
      id: '1',
      surname: 'Smith',
      persons: HasMany<Person>(),
    ).init(repository);

    final p1 = Person(name: 'a', age: 1);
    final p2 = Person(name: 'b', age: 2);
    var notifier = family.persons.watch();

    for (var i = 0; i < 4; i++) {
      if (i == 1) family.persons.add(p1);
      if (i == 2) family.persons.add(p2);
      if (i == 3) family.persons.remove(p1);
      notifier.addListener((state) {
        if (i == 0) expect(state.model, <Person>{});
        if (i == 1) expect(state.model, {p1});
        if (i == 2) expect(state.model, {p1, p2});
        if (i == 3) expect(state.model, {p2});
      });
    }
  });
}
