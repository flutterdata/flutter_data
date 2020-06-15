import 'package:flutter_data/flutter_data.dart';
import 'package:test/test.dart';

import '../../models/family.dart';
import '../../models/house.dart';
import '../../models/person.dart';
import '../setup.dart';

void main() async {
  setUpAll(setUpAllFn);
  tearDownAll(tearDownAllFn);

  // serialization tests

  test('serialize', () {
    final manager = injection.locator<DataManager>();
    final personRepo = injection.locator<Repository<Person>>();
    final houseRepo = injection.locator<Repository<House>>();

    var person = Person(id: '1', name: 'Franco', age: 28).init(personRepo);
    var personRel = HasMany<Person>({person}, manager);
    var house = House(id: '1', address: '123 Main St').init(houseRepo);
    var houseRel = BelongsTo<House>(house, manager);

    var family = Family(
        id: '1', surname: 'Smith', residence: houseRel, persons: personRel);

    var repo = injection.locator<Repository<Family>>() as RemoteAdapter<Family>;
    var map = repo.serialize(family);
    expect(map, {
      'id': '1',
      'surname': 'Smith',
      'residence': houseRel.key,
      'persons': personRel.keys,
      'dacha': null,
      'dogs': null,
    });
  });

  test('serialize with relationships', () {
    var repo = injection.locator<Repository<Family>>() as RemoteAdapter<Family>;
    final personRepo = injection.locator<Repository<Person>>();
    final houseRepo = injection.locator<Repository<House>>();

    var person = Person(id: '1', name: 'John', age: 37).init(personRepo);
    var house = House(id: '1', address: '123 Main St').init(houseRepo);
    var family = Family(
            id: '1',
            surname: 'Smith',
            residence: house.asBelongsTo,
            persons: {person}.asHasMany)
        .init(repo);

    var obj = repo.serialize(family);
    expect(obj, isA<Map<String, dynamic>>());
    expect(obj, {
      'id': '1',
      'surname': 'Smith',
      'residence': keyFor(house),
      'persons': [keyFor(person)],
      'dacha': null,
      'dogs': null,
    });
  });

  test('deserialize', () {
    var manager = injection.locator<DataManager>();
    final personRepo = injection.locator<Repository<Person>>();
    final houseRepo = injection.locator<Repository<House>>();

    var person = Person(id: '1', name: 'Franco', age: 28).init(personRepo);
    var personRel = HasMany<Person>({person}, manager);
    var house = House(id: '1', address: '123 Main St').init(houseRepo);
    var houseRel = BelongsTo<House>(house, manager);

    var map = {
      'id': '1',
      'surname': 'Smith',
      'residence': houseRel.key,
      'persons': personRel.keys,
    };

    var repo = injection.locator<Repository<Family>>() as RemoteAdapter<Family>;
    var family = repo.deserialize(map);
    expect(
        family,
        Family(
          id: '1',
          surname: 'Smith',
          residence: houseRel,
          persons: personRel,
        ));
  });

  test('deserialize existing', () {
    var repo = injection.locator<Repository<Family>>() as RemoteAdapter<Family>;
    repo.box.clear();
    expect(repo.box.keys, isEmpty);
    var family = Family(surname: 'Moletto').init(repo);

    // simulate "save"
    var obj = {'id': '1098', 'surname': 'Moletto'};
    var family2 = repo.deserialize(obj, key: keyFor(family));

    expect(family2.isNew, false); // also checks if the model was init'd
    expect(family2, Family(id: '1098', surname: 'Moletto'));
    expect(repo.box.keys, [keyFor(family2)]);
  });

  test('deserialize many local for same remote ID', () {
    var repo = injection.locator<Repository<Family>>() as RemoteAdapter<Family>;
    repo.box.clear();
    expect(repo.box.keys, isEmpty);

    final family = Family(surname: 'Moletto').init(repo);
    final family2 = Family(surname: 'Zandiver').init(repo);

    // simulate "save" for family
    final family1b = repo.deserialize({
      'id': '1298',
      'surname': 'Helsinki',
    }, key: keyFor(family));

    // simulate "save" for family2
    final family2b = repo.deserialize({
      'id': '1298',
      'surname': 'Oslo',
    }, key: keyFor(family2));

    // since obj returned with same ID
    expect(keyFor(family1b), keyFor(family2b));
  });

  test('deserialize with relationships', () {
    var repo = injection.locator<Repository<Family>>() as RemoteAdapter<Family>;

    final houseRepo = injection.locator<Repository<House>>();
    final personRepo = injection.locator<Repository<Person>>();

    final house = House(id: '1', address: '123 Main St').init(houseRepo);
    final person = Person(id: '1', name: 'John', age: 21).init(personRepo);

    var obj = {
      'id': '1',
      'surname': 'Smith',
      'residence': keyFor(house),
      'persons': [keyFor(person)]
    };

    var family = repo.deserialize(obj);

    expect(family.isNew, false); // also checks if the model was init'd
    expect(family, Family(id: '1', surname: 'Smith'));
    expect(family.residence.value.address, '123 Main St');
    expect(family.persons.first.age, 21);
  });

  test('findOne (reload) without ID', () async {
    final repo = injection.locator<Repository<Family>>();
    final family = Family(surname: 'Zliedowski').init(repo);
    final f2 = Family(surname: 'Zliedowski').init(repo, key: keyFor(family));
    final f3 = await family.reload();
    expect(family, f2);
    expect(family, f3);
  });

  test('delete model with and without ID', () async {
    final repository = injection.locator<Repository<Person>>();
    await repository.box.clear();

    // create a person WITH ID and assert it's there
    final person = Person(id: '21103', name: 'John', age: 54).init(repository);
    expect(repository.localFindAll(), hasLength(1));

    // delete that person and assert it's not there
    await person.delete();
    expect(repository.localFindAll(), hasLength(0));

    // create a person WITHOUT ID and assert it's there
    final person2 = Person(name: 'Peter', age: 101).init(repository);
    expect(repository.localFindAll(), hasLength(1));

    // delete that person and assert it's not there
    await person2.delete();
    expect(repository.localFindAll(), hasLength(0));
  });
}
