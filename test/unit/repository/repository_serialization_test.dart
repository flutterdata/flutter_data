import 'dart:convert';

import 'package:flutter_data/flutter_data.dart';
import 'package:test/test.dart';

import '../../models/family.dart';
import '../../models/house.dart';
import '../../models/person.dart';
import '../../models/pet.dart';
import '../setup.dart';

void main() async {
  setUpAll(setUpAllFn);
  tearDownAll(tearDownAllFn);
  setUp(setUpFn);

  test('serialize', () {
    final person = Person(id: '23', name: 'Ko', age: 24);
    expect(personRepository.serialize(person),
        {'_id': '23', 'name': 'Ko', 'age': 24});
  });

  test('serialize rel id', () {
    final p2 = Person(
            name: 'Ko',
            age: 24,
            family: Family(id: '332', surname: 'Tao').asBelongsTo)
        .init(manager: manager);
    expect(personRepository.serialize(p2),
        {'_id': null, 'name': 'Ko', 'age': 24, 'family_id': '332'});
  });

  test('serialize embedded relationships', () {
    final f1 = Family(
            id: '334',
            surname: 'Zhan',
            residence: House(id: '1', address: 'Zhiwan 2').asBelongsTo,
            dogs: {Dog(id: '1', name: 'Pluto'), Dog(id: '2', name: 'Ricky')}
                .asHasMany)
        .init(manager: manager);

    final serialized = familyRepository.serialize(f1);
    expect(serialized, {
      'id': '334',
      'surname': 'Zhan',
      'residence_id': '1',
      'dogs': ['1', '2']
    });
    expect(json.encode(serialized), isA<String>());
  });

  test('deserialize multiple', () {
    final models = personRepository.deserialize([
      {'_id': '23', 'name': 'Ko', 'age': 24},
      {'_id': '26', 'name': 'Ze', 'age': 58}
    ], save: false).models;

    expect(models, [
      Person(id: '23', name: 'Ko', age: 24).init(manager: manager),
      Person(id: '26', name: 'Ze', age: 58).init(manager: manager)
    ]);
  });

  test('deserialize rel id', () {
    Family(id: '332', surname: 'Tao').init(manager: manager);

    final p1 = personRepository.deserialize([
      {'_id': '27', 'name': 'Ko', 'age': 24, 'family_id': '332'}
    ], save: false).model;

    final p2 = Person(
            id: '27',
            name: 'Ko',
            age: 24,
            family: Family(id: '332', surname: 'Tao').asBelongsTo)
        .init(manager: manager);

    expect(p1, p2);

    // this works because p2 was initialized!
    expect(p1.family.value, p2.family.value);
  });

  test('deserialize with embedded relationships', () {
    final data = familyRepository.deserialize([
      {
        'id': '1',
        'surname': 'Byrde',
        'persons': <Map<String, dynamic>>[
          {'_id': '1', 'name': 'Wendy', 'age': 58},
          {'_id': '2', 'name': 'Marty', 'age': 60},
        ],
        'residence': <String, dynamic>{
          'id': '1',
          'address': '123 Main St',
        }
      }
    ], save: false);

    final f1 = data.model;
    final f2 = Family(id: '1', surname: 'Byrde');

    expect(f1, f2);

    // f2 isn't initialized, so f1.persons will be empty
    expect(f1.persons, isEmpty);

    // check included instead
    expect(data.included, [
      Person(id: '1', name: 'Wendy', age: 58),
      Person(id: '2', name: 'Marty', age: 60),
      House(id: '1', address: '123 Main St'),
    ]);
  });

  test('deserialize with nested embedded relationships', () {
    final data = personRepository.deserialize([
      {
        '_id': '1',
        'name': 'Marty',
        'family': <String, dynamic>{
          'id': '1',
          'surname': 'Byrde',
          'residence': <String, dynamic>{
            'id': '1',
            'address': '123 Main St',
          }
        },
      }
    ], save: false);

    expect(data.included, [
      Family(id: '1', surname: 'Byrde'),
      House(id: '1', address: '123 Main St'),
    ]);
  });

  test('deserialize existing (with save)', () {
    final family = Family(surname: 'Moletto').init(manager: manager);

    // simulate "save"
    final obj = {'id': '1098', 'surname': 'Moletto'};
    final family2 = familyRepository
        .deserialize(obj, key: keyFor(family), save: true)
        .model;

    expect(family2.isNew, false); // also checks if the model was init'd
    expect(family2, Family(id: '1098', surname: 'Moletto'));
    expect(familyRepository.box.keys, [keyFor(family2)]);
  });

  test('deserialize many local for same remote ID', () {
    final family = Family(surname: 'Moletto').init(manager: manager);
    final family2 = Family(surname: 'Zandiver').init(manager: manager);

    // simulate "save" for family
    final family1b = familyRepository.deserialize({
      'id': '1298',
      'surname': 'Helsinki',
    }, key: keyFor(family), save: true).model;

    // simulate "save" for family2
    final family2b = familyRepository.deserialize({
      'id': '1298',
      'surname': 'Oslo',
    }, key: keyFor(family2), save: true).model;

    // since obj returned with same ID
    expect(keyFor(family1b), keyFor(family2b));
  });

  // local/internal serialization

  test('local serialize', () {
    final p1r = {Person(id: '1', name: 'Franco', age: 28)}.asHasMany;
    final h1r = House(id: '1', address: '123 Main St').asBelongsTo;

    final family =
        Family(id: '1', surname: 'Smith', residence: h1r, persons: p1r)
            .init(manager: manager);

    final map = familyRepository.localSerialize(family);
    expect(map, {
      'id': '1',
      'surname': 'Smith',
      'residence': h1r.key,
      'persons': p1r.keys,
      'cottage': null,
      'dogs': null,
    });
  });

  test('local deserialize', () {
    final p1r = {Person(id: '1', name: 'Franco', age: 28)}.asHasMany;
    final h1r = House(id: '1', address: '123 Main St').asBelongsTo;

    final map = {
      'id': '1',
      'surname': 'Smith',
      'residence': h1r.key,
      'persons': p1r.keys,
    };

    final family = familyRepository.deserialize(map, save: false).model;
    expect(
        family,
        Family(
          id: '1',
          surname: 'Smith',
          residence: h1r,
          persons: p1r,
        ));
  });

  test('local deserialize with relationships', () {
    final house = House(id: '1', address: '123 Main St').init(manager: manager);
    final person =
        Person(id: '1', name: 'John', age: 21).init(manager: manager);

    final obj = {
      'id': '1',
      'surname': 'Smith',
      'residence': keyFor(house),
      'persons': [keyFor(person)]
    };

    final family =
        familyRepository.localDeserialize(obj).init(manager: manager);

    expect(family.isNew, false); // also checks if the model was init'd
    expect(family, Family(id: '1', surname: 'Smith'));
    expect(family.residence.value.address, '123 Main St');
    expect(family.persons.first.age, 21);
  });
}
