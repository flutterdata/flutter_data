import 'package:flutter_data/flutter_data.dart';
import 'package:test/test.dart';

import '../../models/family.dart';
import '../../models/person.dart';
import '../../models/pet.dart';
import '../setup.dart';

void main() async {
  setUpAll(setUpAllFn);
  tearDownAll(tearDownAllFn);

  test('throws if not initialized', () {
    expect(() {
      return Family(surname: 'Willis').save();
    }, throwsA(isA<AssertionError>()));
  });

  test('init', () async {
    final repo = injection.locator<Repository<Person>>();
    final familyRepo = injection.locator<Repository<Family>>();

    var family = Family(id: '55', surname: 'Kelley').init(familyRepo);
    var model =
        Person(id: '1', name: 'John', age: 27, family: family.asBelongsTo)
            .init(repo);

    // (1) it wires up the relationship (setOwnerInRelationship)
    expect(model.family.key, repo.manager.getKeyForId('families', '55'));

    // (2) it saves the model locally
    expect(model, await repo.findOne(model.id));
  });

  // misc compatibility tests

  test('should reuse key', () {
    var manager = injection.locator<DataManager>();
    var repository = injection.locator<Repository<Person>>();

    // id-less person
    var p1 = Person(name: 'Frank', age: 20).init(repository);
    expect(repository.box.keys, contains(keyFor(p1)));

    // person with new id, reusing existing key
    manager.getKeyForId('people', '221', keyIfAbsent: keyFor(p1));
    var p2 = Person(id: '221', name: 'Frank2', age: 32).init(repository);
    expect(keyFor(p1), keyFor(p2));

    expect(repository.box.keys, contains(keyFor(p2)));
  });

  test('should resolve to the same key', () {
    var dogRepo = injection.locator<Repository<Dog>>();
    var dog = Dog(id: '2', name: 'Walker').init(dogRepo);
    var dog2 = Dog(id: '2', name: 'Walker').init(dogRepo);
    expect(keyFor(dog), keyFor(dog2));
  });

  test('should work with subclasses', () {
    var familyRepo = injection.locator<Repository<Family>>();
    var dogRepo = injection.locator<Repository<Dog>>();
    var dog = Dog(id: '2', name: 'Walker').init(dogRepo);

    var f = Family(surname: 'Walker', dogs: {dog}.asHasMany).init(familyRepo);
    expect(f.dogs.first.name, 'Walker');
  });

  test('data exception equality', () {
    expect(DataException(Exception('whatever'), 410),
        DataException(Exception('whatever'), 410));
    expect(DataException([Exception('whatever')], 410),
        isNot(DataException(Exception('whatever'), 410)));
  });
}
