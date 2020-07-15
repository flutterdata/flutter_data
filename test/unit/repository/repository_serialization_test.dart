import 'dart:convert';

import 'package:flutter_data/flutter_data.dart';
import 'package:test/test.dart';

import '../../models/family.dart';
import '../../models/house.dart';
import '../../models/person.dart';
import '../../models/pet.dart';
import '../setup.dart';

void main() async {
  setUp(setUpFn);

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

  test('deserialize existing (with save)', () {
    final family = Family(surname: 'Moletto').init(owner);

    // simulate "save"
    graph.getKeyForId('families', '1098', keyIfAbsent: keyFor(family));
    final family2 = familyLocalAdapter
        .deserialize({'id': '1098', 'surname': 'Moletto'}).init(owner);

    expect(family2, Family(id: '1098', surname: 'Moletto'));
    expect((familyLocalAdapter as HiveLocalAdapter<Family>).box.keys,
        [keyFor(family2)]);
  });

  test('deserialize many local for same remote ID', () {
    final family = Family(surname: 'Moletto').init(owner);
    final family2 = Family(surname: 'Zandiver').init(owner);

    // simulate "save" for family
    graph.getKeyForId('families', '1298', keyIfAbsent: keyFor(family));
    final family1b = familyLocalAdapter.deserialize({
      'id': '1298',
      'surname': 'Helsinki',
    }).init(owner);

    // simulate "save" for family2
    graph.getKeyForId('families', '1298', keyIfAbsent: keyFor(family2));
    final family2b = familyLocalAdapter.deserialize({
      'id': '1298',
      'surname': 'Oslo',
    }).init(owner);

    // since obj returned with same ID
    expect(keyFor(family1b), keyFor(family2b));
  });

  // local/internal serialization

  test('local serialize', () {
    final p1r = {Person(id: '1', name: 'Franco', age: 28)}.asHasMany;
    final h1r = House(id: '1', address: '123 Main St').asBelongsTo;

    final family =
        Family(id: '1', surname: 'Smith', residence: h1r, persons: p1r)
            .init(owner);

    final map = familyLocalAdapter.serialize(family);
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

    final family = familyLocalAdapter.deserialize(map);
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
    final house = House(id: '1', address: '123 Main St').init(owner);
    final person = Person(id: '1', name: 'John', age: 21).init(owner);

    final obj = {
      'id': '1',
      'surname': 'Smith',
      'residence': keyFor(house),
      'persons': [keyFor(person)]
    };

    final family = familyLocalAdapter.deserialize(obj).init(owner);

    expect(family, Family(id: '1', surname: 'Smith'));
    expect(family.residence.value.address, '123 Main St');
    expect(family.persons.first.age, 21);
  });
}
