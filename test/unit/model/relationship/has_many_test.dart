import 'package:flutter_data/flutter_data.dart';
import 'package:test/test.dart';

import '../../../models/family.dart';
import '../../../models/person.dart';
import '../../setup.dart';

void main() async {
  setUpAll(setUpAllFn);
  tearDownAll(tearDownAllFn);

  test('HasMany is a Set', () {
    final anne = Person(name: 'Anne', age: 59).init(manager);
    final f1 =
        Family(surname: 'Mayer', persons: {anne}.asHasMany).init(manager);

    f1.persons.add(anne);
    f1.persons.add(anne);
    expect(f1.persons.length, 1);
    expect(f1.persons.lookup(anne), anne);

    final agnes = Person(name: 'Agnes', age: 29).init(manager);
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
    final repo = injection.locator<FamilyRepositoryWithStandardJSONAdapter>();
    final personRepo = injection.locator<Repository<Person>>();

    final marty = {'id': '71', 'name': 'Marty', 'age': 52};
    final wendy = {'id': '72', 'name': 'Wendy', 'age': 54};

    final familyJson = {
      'surname': 'Byrde',
      'persons': [marty, wendy]
    };

    repo.deserialize(familyJson);

    expect(await personRepo.findOne('71'), predicate((p) => p.id == '71'));
    expect(await personRepo.findOne('72'), predicate((p) => p.age == 54));
  });

  test('maintain relationship reference validity', () {
    final repo =
        injection.locator<Repository<Family>>() as RemoteAdapter<Family>;

    final brian = Person(name: 'Brian', age: 52).init(manager);
    final family =
        Family(id: '229', surname: 'Rose', persons: {brian}.asHasMany)
            .init(manager);
    expect(family.persons.length, 1);

    // new family comes in locally with no persons relationship info
    final family2 =
        Family(id: '229', surname: 'Rose', persons: HasMany()).init(manager);
    // it should keep the relationships unaltered
    expect(family2.persons.length, 1);

    // new family comes in from API (simulate) with no persons relationship info
    final family3 = repo.deserialize({'id': '229', 'surname': 'Rose'});
    // it should keep the relationships unaltered
    expect(family3.persons.length, 1);

    // new family comes in from API (simulate) with empty persons relationship
    final family4 =
        repo.deserialize({'id': '229', 'surname': 'Rose', 'persons': []});
    // it should keep the relationships unaltered
    expect(family4.persons.length, 0);

    final family5 = repo.deserialize({
      'id': '229',
      'surname': 'Rose',
      'persons': ['people#231aaa']
    });

    manager.getKeyForId('people', '231', keyIfAbsent: 'people#231aaa');
    final axl = Person(id: '231', name: 'Axl', age: 58).init(manager);
    expect(family5.persons, {axl});
  });

  test('watch', () async {
    final family = Family(
      id: '1',
      surname: 'Smith',
      persons: HasMany<Person>(),
    ).init(manager);

    final p1 = Person(name: 'a', age: 1).init(manager);
    final p2 = Person(name: 'b', age: 2).init(manager);
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
