import 'package:flutter_data/flutter_data.dart';
import 'package:test/test.dart';

import '../../../models/family.dart';
import '../../../models/person.dart';
import '../../setup.dart';

void main() async {
  setUpAll(setUpAllFn);
  tearDownAll(tearDownAllFn);

  test('HasMany is a Set', () {
    final repository = injection.locator<Repository<Family>>();
    final anne = Person(name: 'Anne', age: 59);
    final f1 =
        Family(surname: 'Mayer', persons: {anne}.asHasMany).init(repository);

    f1.persons.add(anne);
    f1.persons.add(anne);
    expect(f1.persons.length, 1);
    expect(f1.persons.lookup(anne), anne);

    f1.persons.manager = injection.locator<DataManager>();
    f1.persons.initializeModels();
    final agnes = Person(name: 'Agnes', age: 29);
    f1.persons.add(agnes);
    expect(f1.persons.length, 2);

    f1.persons.remove(anne);
    expect(f1.persons, {agnes});
    f1.persons.add(null);
    expect(f1.persons, {agnes});

    f1.persons.clear();
    expect(f1.persons.length, 0);
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

  test('maintain relationship reference validity', () {
    var repo = injection.locator<Repository<Family>>() as RemoteAdapter<Family>;
    var personRepo = injection.locator<Repository<Person>>();

    var brian = Person(name: 'Brian', age: 52);
    var family = Family(id: '229', surname: 'Rose', persons: {brian}.asHasMany)
        .init(repo);
    expect(family.persons.length, 1);

    // new family comes in locally with no persons relationship info
    var family2 =
        Family(id: '229', surname: 'Rose', persons: HasMany()).init(repo);
    // it should keep the relationships unaltered
    expect(family2.persons.length, 1);

    // new family comes in from API (simulate) with no persons relationship info
    var family3 = repo.deserialize({'id': '229', 'surname': 'Rose'});
    // it should keep the relationships unaltered
    expect(family3.persons.length, 1);

    // new family comes in from API (simulate) with empty persons relationship
    var family4 =
        repo.deserialize({'id': '229', 'surname': 'Rose', 'persons': []});
    // it should keep the relationships unaltered
    expect(family4.persons.length, 0);

    var family5 = repo.deserialize({
      'id': '229',
      'surname': 'Rose',
      'persons': ['people#231aaa']
    });

    var axl = Person(id: '231', name: 'Axl', age: 58)
        .init(personRepo, key: 'people#231aaa');
    expect(family5.persons, {axl});
  });

  test('watch', () async {
    final repository = injection.locator<Repository<Family>>();
    final family = Family(
      id: '1',
      surname: 'Smith',
      persons: HasMany<Person>(),
    ).init(repository);

    final p1 = Person(name: 'a', age: 1);
    final p2 = Person(name: 'b', age: 2);
    final notifier = family.persons.watch();

    var i = 0;
    notifier.addListener(
      expectAsync1((persons) {
        if (i == 0) expect(persons, {p1});
        if (i == 1) expect(persons, {p1, p2});
        if (i == 2) expect(persons, {p2});
        if (i == 3) expect(persons, {p2, p1});
        i++;
      }, count: 4),
      fireImmediately: false,
    );

    family.persons.add(p1);
    family.persons.add(p2);
    family.persons.remove(p1);
    family.persons.add(p1);
  });
}
