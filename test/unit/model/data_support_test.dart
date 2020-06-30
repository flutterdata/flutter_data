import 'package:flutter_data/flutter_data.dart';
import 'package:test/test.dart';

import '../../models/family.dart';
import '../../models/person.dart';
import '../../models/pet.dart';
import '../setup.dart';

void main() async {
  setUpAll(setUpAllFn);
  tearDownAll(tearDownAllFn);
  setUp(setUpFn);

  test('init', () async {
    final family = Family(id: '55', surname: 'Kelley').init(manager: manager);
    final model =
        Person(id: '1', name: 'John', age: 27, family: family.asBelongsTo)
            .init(manager: manager);

    // (1) it wires up the relationship (setOwnerInRelationship)
    expect(model.family.key, manager.getKeyForId('families', '55'));

    // (2) it saves the model locally
    expect(model, await personRepository.findOne(model.id));
  });

  test('findOne (reload) without ID', () async {
    final family = Family(surname: 'Zliedowski').init(manager: manager);
    final f2 = Family(surname: 'Zliedowski').was(family);

    final f3 = await family.reload();
    expect(keyFor(family), keyFor(f2));
    expect(keyFor(family), keyFor(f3));
  });

  test('delete model with and without ID', () async {
    // create a person WITH ID and assert it's there
    final person =
        Person(id: '21103', name: 'John', age: 54).init(manager: manager);
    expect(personRepository.localFindAll(), hasLength(1));

    // delete that person and assert it's not there
    await person.delete();
    expect(personRepository.localFindAll(), hasLength(0));

    // create a person WITHOUT ID and assert it's there
    final person2 = Person(name: 'Peter', age: 101).init(manager: manager);
    expect(personRepository.localFindAll(), hasLength(1));

    // delete that person and assert it's not there
    await person2.delete();
    expect(personRepository.localFindAll(), hasLength(0));
  });

  test('should reuse key', () {
    // id-less person
    final p1 = Person(name: 'Frank', age: 20).init(manager: manager);
    expect(personRepository.box.keys, contains(keyFor(p1)));

    // person with new id, reusing existing key
    manager.getKeyForId('people', '221', keyIfAbsent: keyFor(p1));
    final p2 =
        Person(id: '221', name: 'Frank2', age: 32).init(manager: manager);
    expect(keyFor(p1), keyFor(p2));

    expect(personRepository.box.keys, contains(keyFor(p2)));
  });

  test('should resolve to the same key', () {
    final dog = Dog(id: '2', name: 'Walker').init(manager: manager);
    final dog2 = Dog(id: '2', name: 'Walker').init(manager: manager);
    expect(keyFor(dog), keyFor(dog2));
  });

  test('should work with subclasses', () {
    final dog = Dog(id: '2', name: 'Walker').init(manager: manager);
    final f =
        Family(surname: 'Walker', dogs: {dog}.asHasMany).init(manager: manager);
    expect(f.dogs.first.name, 'Walker');
  });

  test('data exception equality', () {
    expect(DataException(Exception('whatever'), 410),
        DataException(Exception('whatever'), 410));
    expect(DataException([Exception('whatever')], 410),
        isNot(DataException(Exception('whatever'), 410)));
  });
}
