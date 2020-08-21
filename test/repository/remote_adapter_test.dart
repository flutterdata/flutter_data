import 'dart:convert';

import 'package:flutter_data/flutter_data.dart';
import 'package:test/test.dart';

import '../_support/family.dart';
import '../_support/house.dart';
import '../_support/person.dart';
import '../_support/setup.dart';

void main() async {
  setUp(setUpFn);
  tearDown(tearDownFn);

  test('findAll', () async {
    final family1 = Family(id: '1', surname: 'Smith');
    final family2 = Family(id: '2', surname: 'Jones');

    await familyRemoteAdapter.save(family1);
    await familyRemoteAdapter.save(family2);
    final families = await familyRemoteAdapter.findAll();

    expect(families, [family1, family2]);
  });

  test('findOne', () async {
    final family1 = Family(id: '1', surname: 'Smith');

    await familyRemoteAdapter.save(family1); // possible to save without init
    final family = await familyRemoteAdapter.findOne('1');
    expect(family, family1);
  });

  test('findOne with null', () {
    expect(() async => await familyRemoteAdapter.findOne(null),
        throwsA(isA<AssertionError>()));
  });

  test('findOne with includes', () async {
    final data = familyRemoteAdapter.deserialize(json.decode('''
      { "id": "1", "surname": "Smith", "persons": [{"_id": "1", "name": "Stan", "age": 31}] }
    '''));
    expect(data.model, Family(id: '1', surname: 'Smith'));
    expect(data.included, [Person(id: '1', name: 'Stan', age: 31)]);
  });

  test('create and save', () async {
    final house = House(id: '25', address: '12 Lincoln Rd');

    // the house is not initialized, so we shouldn't be able to find it
    expect(await houseRemoteAdapter.findOne(house.id), isNull);

    // now initialize
    house.init(container);

    // repo.findOne works because the House repo is remote=false
    expect(await houseRemoteAdapter.findOne(house.id), house);
  });

  test('save and find', () async {
    final family = Family(id: '32423', surname: 'Toraine');
    await familyRemoteAdapter.save(family);

    final family2 = await familyRemoteAdapter.findOne('32423');
    expect(family, family2);
  });

  test('delete', () async {
    // init a person
    final person = Person(id: '1', name: 'John', age: 21).init(container);
    // it does have a key
    expect(graph.getKeyForId('people', person.id), isNotNull);

    // now delete
    await personRemoteAdapter.delete(person.id);

    // so fetching by id again is null
    expect(await personRemoteAdapter.findOne(person.id), isNull);

    // and now key & id are both non-existent
    expect(graph.getNode(keyFor(person)), isNull);
    expect(graph.getKeyForId('people', person.id), isNull);
  });
}
