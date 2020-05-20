import 'package:flutter_data/flutter_data.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../models/family.dart';
import '../../models/house.dart';
import '../../models/person.dart';
import '../setup.dart';

void main() async {
  setUpAll(setUpAllFn);
  tearDownAll(tearDownAllFn);

  test('locator', () {
    var repo = injection.locator<Repository<Person>>();
    expect(repo.manager.locator, isNotNull);
  });

  test('findAll', () async {
    var repo = injection.locator<Repository<Family>>();
    var family1 = Family(id: '1', surname: 'Smith');
    var family2 = Family(id: '2', surname: 'Jones');

    await repo.save(family1);
    await repo.save(family2);
    var families = await repo.findAll();

    expect(families, [family1, family2]);
  });

  test('findOne', () async {
    var repo = injection.locator<Repository<Family>>();
    var family1 = Family(id: '1', surname: 'Smith');

    await repo.save(family1);
    var family = await repo.findOne('1');
    expect(family, family1);
  });

  test('create and save', () async {
    var repo = injection.locator<Repository<House>>();
    var house = House(id: '25', address: '12 Lincoln Rd').init(repo);
    // repo.findOne works because the House repo is remote=false
    expect(await repo.findOne(house.id), house);
    // but overriding remote works
    // throws an unsupported error as baseUrl was not configured
    expect(() async {
      return await repo.findOne(house.id, remote: true);
    }, throwsA(isA<UnsupportedError>()));
  });

  test('save and find', () async {
    var repo = injection.locator<Repository<Family>>();
    var family = Family(id: '32423', surname: 'Toraine');
    await repo.save(family);

    var family2 = await repo.findOne('32423');
    expect(family2.isNew, false);
    expect(family, family2);
  });

  test('delete', () async {
    final repo = injection.locator<Repository<Person>>();
    final person = Person(id: '1', name: 'John', age: 21).init(repo);
    await repo.delete(person.id);
    var p2 = await repo.findOne(person.id);
    expect(p2, isNull);
    expect(repo.manager.keysBox.get('people#${person.id}'), isNull);
  });

  test('returning a different remote ID for a requested ID is not supported',
      () {
    var repo = injection.locator<Repository<Family>>() as RemoteAdapter<Family>;
    repo.box.clear();
    expect(repo.box.keys, isEmpty);
    var family0 = Family(id: '2908', surname: 'Moletto').init(repo);

    // simulate a "findOne" with some id
    var family = Family(id: '2905', surname: 'Moletto').init(repo);
    var obj2 = {
      'id': '2908', // that returns a different ID (already in the system)
      'surname': 'Oslo',
    };
    var family2 = repo.deserialize(obj2, key: keyFor(family));

    // even though we supplied family.key, it will be different (family0's)
    expect(keyFor(family2), isNot(keyFor(family)));
    expect(repo.box.keys, [keyFor(family0)]);
  });

  test('remote ID can be replaced with public methods', () {
    var repo = injection.locator<Repository<Family>>() as RemoteAdapter<Family>;
    repo.box.clear();
    expect(repo.box.keys, isEmpty);
    Family(id: '2908', surname: 'Moletto').init(repo);
    // app is now ready and loaded one family from local storage

    // simulate a "findOne" with some id
    var family = Family(id: '2905', surname: 'Moletto').init(repo);
    var originalKey = keyFor(family);
    var obj2 = {
      'id': '2908', // that returns a different ID (already in the system)
      'surname': 'Oslo',
    };
    var family2 = repo.deserialize(obj2, key: keyFor(family));

    // expect family to have been deleted by init, family2 remains
    expect(repo.box.keys, [keyFor(family2)]);
    expect(repo.manager.keysBox.keys, isNot(contains('families#${family.id}')));
    expect(repo.manager.keysBox.keys, contains('families#${family2.id}'));

    // delete family2 and its key
    repo.delete(family2.id);

    // expect no keys remain
    expect(repo.box.keys, isEmpty);
    expect(repo.manager.keysBox.keys, isNot(contains('families#${family.id}')));
    expect(
        repo.manager.keysBox.keys, isNot(contains('families#${family2.id}')));

    // associate new id to original existing key
    family2.init(repo, key: originalKey, save: true);

    // original key should now be associated to the deserialized model
    expect(repo.manager.keysBox.get('families#${family2.id}'), originalKey);
    expect(repo.box.keys, [originalKey]);
    expect(repo.box.get(originalKey), family2);
  });

  test('custom login adapter', () async {
    var repo = injection.locator<Repository<Person>>() as PersonLoginAdapter;
    var token = await repo.login('email@email.com', 'password');
    expect(token, 'zzz1');
  });

  test('mock repository', () async {
    var bloc = Bloc(MockFamilyRepository());
    when(bloc.repo.findAll())
        .thenAnswer((_) => Future(() => [Family(surname: 'Smith')]));
    final families = await bloc.repo.findAll();
    expect(families, predicate((list) => list.first.surname == 'Smith'));
    verify(bloc.repo.findAll());
  });
}
