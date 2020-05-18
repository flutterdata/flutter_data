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
    var repo = injection.locator<Repository<Person>>();
    var person = Person(id: '1', name: 'zzz', age: 7).init(repo);

    var rel = HasMany<Person>({}, manager);
    expect(rel.length, 0);

    rel = HasMany<Person>({person}, manager);
    expect(rel.first.key, manager.getKey('1'));
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
        [manager.getKey('1')],
        false,
        manager
      ]
    });
    var person = Person(id: '1', name: 'zzz', age: 7).init(repo);

    expect(rel, HasMany<Person>({person}, manager));
    expect(rel.first, person);
    expect(rel.first.key, manager.getKey('1'));
  });

  test('does not contain nulls', () {
    var repo = injection.locator<Repository<Person>>();
    var person = Person(name: 'Claire', age: 31).init(repo);
    var rel = HasMany<Person>({person}, repo.manager);

    rel.add(null);
    expect(rel, {person});

    rel.keys.add(null);
    expect(rel.toSet(), {person});
  });

  test('maintain relationship reference validity', () {
    var repo = injection.locator<Repository<Family>>() as RemoteAdapter<Family>;
    var personRepo = injection.locator<Repository<Person>>();

    // var brian = Person(name: 'Brian', age: 52);
    // var family = Family(id: '229', surname: 'Rose', persons: {brian}.asHasMany)
    //     .init(repo);
    // expect(family.persons.length, 1);

    // // // new family comes in locally with no persons relationship info
    // // var family2 = Family(id: '229', surname: 'Rose').init(repo);
    // // // it should keep the relationships unaltered
    // // expect(family2.persons.length, 1);

    // // new family comes in from API (simulate) with no persons relationship info
    // var family3 = repo.deserialize({'id': '229', 'surname': 'Rose'});
    // // it should keep the relationships unaltered
    // expect(family3.persons.length, 1);

    // new family comes in from API (simulate) with empty persons relationship
    var family4 =
        repo.deserialize({'id': '229', 'surname': 'Rose', 'persons': []});
    // it should keep the relationships unaltered
    expect(family4.persons.length, 0);

    var family5 = repo.deserialize({
      'id': '229',
      'surname': 'Rose',
      'persons': ['231']
    });

    var axl = Person(id: '231', name: 'Axl', age: 58).init(personRepo);
    expect(family5.persons, {axl});
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
