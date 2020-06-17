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

    final family = Family(id: '55', surname: 'Kelley').init(manager);
    final model =
        Person(id: '1', name: 'John', age: 27, family: family.asBelongsTo)
            .init(manager);

    // (1) it wires up the relationship (setOwnerInRelationship)
    expect(model.family.key, repo.manager.getKeyForId('families', '55'));

    // (2) it saves the model locally
    expect(model, await repo.findOne(model.id));
  });

  // misc compatibility tests

  test('should reuse key', () {
    final repository = injection.locator<Repository<Person>>();

    // id-less person
    final p1 = Person(name: 'Frank', age: 20).init(manager);
    expect(repository.box.keys, contains(keyFor(p1)));

    // person with new id, reusing existing key
    manager.getKeyForId('people', '221', keyIfAbsent: keyFor(p1));
    final p2 = Person(id: '221', name: 'Frank2', age: 32).init(manager);
    expect(keyFor(p1), keyFor(p2));

    expect(repository.box.keys, contains(keyFor(p2)));
  });

  test('should resolve to the same key', () {
    final dog = Dog(id: '2', name: 'Walker').init(manager);
    final dog2 = Dog(id: '2', name: 'Walker').init(manager);
    expect(keyFor(dog), keyFor(dog2));
  });

  test('should work with subclasses', () {
    final dog = Dog(id: '2', name: 'Walker').init(manager);
    final f = Family(surname: 'Walker', dogs: {dog}.asHasMany).init(manager);
    expect(f.dogs.first.name, 'Walker');
  });

  test('data exception equality', () {
    expect(DataException(Exception('whatever'), 410),
        DataException(Exception('whatever'), 410));
    expect(DataException([Exception('whatever')], 410),
        isNot(DataException(Exception('whatever'), 410)));
  });
}
