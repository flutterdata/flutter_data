import 'dart:convert';

import 'package:flutter_data/flutter_data.dart';
import 'package:test/test.dart';

import '../_support/family.dart';
import '../_support/house.dart';
import '../_support/person.dart';
import '../_support/pet.dart';
import '../_support/setup.dart';

void main() async {
  setUp(setUpFn);
  tearDown(tearDownFn);

  test('serialize', () {
    final person = Person(id: '23', name: 'Ko', age: 24);
    expect(personRemoteAdapter.serialize(person),
        {'_id': '23', 'name': 'Ko', 'age': 24});
  });

  test('serialize with relationship', () {
    final p2 = Person(
            name: 'Ko',
            age: 24,
            family: Family(id: '332', surname: 'Tao').asBelongsTo)
        .init(owner);
    expect(personRemoteAdapter.serialize(p2),
        {'_id': null, 'name': 'Ko', 'age': 24, 'family_id': '332'});
  });

  test('serialize embedded relationships', () {
    final f1 = Family(
            id: '334',
            surname: 'Zhan',
            residence: House(id: '1', address: 'Zhiwan 2').asBelongsTo,
            dogs: {Dog(id: '1', name: 'Pluto'), Dog(id: '2', name: 'Ricky')}
                .asHasMany)
        .init(owner);

    final serialized = familyRemoteAdapter.serialize(f1);
    expect(serialized, {
      'id': '334',
      'surname': 'Zhan',
      'residence_id': '1',
      'dogs': ['1', '2']
    });
    expect(json.encode(serialized), isA<String>());
  });

  test('deserialize multiple', () {
    final models = personRemoteAdapter.deserialize([
      {'_id': '23', 'name': 'Ko', 'age': 24},
      {'_id': '26', 'name': 'Ze', 'age': 58}
    ]).models;

    expect(models, [
      Person(id: '23', name: 'Ko', age: 24),
      Person(id: '26', name: 'Ze', age: 58)
    ]);
  });

  test('deserialize relationship with id', () {
    final p1 = personRemoteAdapter
        .deserialize([
          {'_id': '27', 'name': 'Ko', 'age': 24, 'family_id': '332'}
        ])
        .model
        .init(owner);

    //

    Family(id: '332', surname: 'Tao').init(owner);

    final p2 = Person(
            id: '27',
            name: 'Ko',
            age: 24,
            family: Family(id: '332', surname: 'Tao').asBelongsTo)
        .init(owner);

    expect(p1, p2);

    // this works because p2 was initialized!
    expect(p1.family.value, p2.family.value);
  });

  test('deserialize with embedded relationships', () {
    final data = familyRemoteAdapter.deserialize(
      [
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
      ],
    );

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
    final data = personRemoteAdapter.deserialize(
      [
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
      ],
    );

    expect(data.included, [
      Family(id: '1', surname: 'Byrde'),
      House(id: '1', address: '123 Main St'),
    ]);
  });
}
