import 'package:flutter_data/flutter_data.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../models/family.dart';
import '../../models/house.dart';
import '../../models/person.dart';
import '../mocks.dart';
import '../setup.dart';

void main() async {
  setUpAll(setUpAllFn);
  tearDownAll(tearDownAllFn);
  setUp(setUpFn);

  test('findAll', () async {
    final family1 = Family(id: '1', surname: 'Smith');
    final family2 = Family(id: '2', surname: 'Jones');

    await familyRepository.save(family1);
    await familyRepository.save(family2);
    final families = await familyRepository.findAll();

    expect(families, [family1, family2]);
  });

  test('findOne', () async {
    final family1 = Family(id: '1', surname: 'Smith');

    await familyRepository.save(family1); // possible to save without init
    final family = await familyRepository.findOne('1');
    expect(family, family1);
  });

  test('create and save', () async {
    final house = House(id: '25', address: '12 Lincoln Rd');

    // the house is not initialized, so we shouldn't be able to find it
    expect(await houseRepository.findOne(house.id), isNull);

    // now initialize
    house.init(manager: manager);

    // repo.findOne works because the House repo is remote=false
    expect(await houseRepository.findOne(house.id), house);

    // but overriding remote works
    // throws an unsupported error as baseUrl was not configured
    expect(() async {
      return await houseRepository.findOne(house.id, remote: true);
    }, throwsA(isA<UnsupportedError>()));
  });

  test('save and find', () async {
    final family = Family(id: '32423', surname: 'Toraine');
    await familyRepository.save(family);

    final family2 = await familyRepository.findOne('32423');
    expect(family2.isNew, false);
    expect(family, family2);
  });

  test('delete', () async {
    final person =
        Person(id: '1', name: 'John', age: 21).init(manager: manager);
    await personRepository.delete(person.id);
    final p2 = await personRepository.findOne(person.id);
    expect(p2, isNull);
    expect(manager.metaBox.get('people#${keyFor(person)}'), isNull);
    // the ID->key node is left orphan, which
    // will eventually be removed with serialization
    expect(manager.metaBox.get('id:people#${person.id}'), isNotNull);
  });

  test('delete without init', () async {
    final person = Person(id: '911', name: 'Sammy', age: 47);
    await personRepository.delete(person.id);
    expect(await personRepository.findOne(person.id), isNull);
  });

  test('returning a different remote ID for a requested ID is not supported',
      () {
    Family(id: '2908', surname: 'Moletto').init(manager: manager);

    // simulate a "findOne" with some id
    final family =
        Family(id: '2905', surname: 'Moletto').init(manager: manager);
    final obj2 = {
      'id': '2908', // that returns a different ID (already in the system)
      'surname': 'Oslo',
    };
    final family2 =
        familyRepository.deserialize(obj2, key: keyFor(family)).model;

    // even though we supplied family.key, it will be different (family0's)
    expect(keyFor(family2), isNot(keyFor(family)));
  });

  test('custom login adapter', () async {
    final repo = personRepository as PersonLoginAdapter;
    final token = await repo.login('email@email.com', 'password');
    expect(token, 'zzz1');
  });

  test('mock repository', () async {
    final bloc = Bloc(MockFamilyRepository());
    when(bloc.repo.findAll())
        .thenAnswer((_) => Future(() => [Family(surname: 'Smith')]));
    final families = await bloc.repo.findAll();
    expect(families, predicate((list) => list.first.surname == 'Smith'));
    verify(bloc.repo.findAll());
  });
}

class Bloc {
  final Repository<Family> repo;
  Bloc(this.repo);
}
