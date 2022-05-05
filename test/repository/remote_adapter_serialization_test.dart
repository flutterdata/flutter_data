import 'dart:convert';

import 'package:flutter_data/flutter_data.dart';
import 'package:test/test.dart';

import '../_support/book.dart';
import '../_support/familia.dart';
import '../_support/house.dart';
import '../_support/node.dart';
import '../_support/person.dart';
import '../_support/pet.dart';
import '../_support/setup.dart';

void main() async {
  setUp(setUpFn);
  tearDown(tearDownFn);

  test('serialize', () async {
    final person = Person(id: '23', name: 'Ko', age: 24);
    expect(container.people.remoteAdapter.serialize(person),
        {'_id': '23', 'name': 'Ko', 'age': 24});
  });

  test('serialize with relationship', () async {
    final familia = Familia(
      surname: 'Tao',
      persons: HasMany({Person(id: '332', name: 'Ko')}),
    );
    expect(container.familia.remoteAdapter.serialize(familia), {
      'surname': 'Tao',
      'persons': ['332']
    });
  });

  test('serialize embedded relationships', () async {
    final f1 = Familia(
        id: '334',
        surname: 'Zhan',
        residence: House(id: '1', address: 'Zhiwan 2').asBelongsTo,
        dogs: {Dog(id: '1', name: 'Pluto'), Dog(id: '2', name: 'Ricky')}
            .asHasMany);

    final serialized = container.familia.remoteAdapter.serialize(f1);
    expect(serialized, {
      'id': '334',
      'surname': 'Zhan',
      // we expect persons: [] as it's default in the Familia class
      'persons': [],
      'residence': '1',
      'dogs': ['1', '2']
    });
    expect(json.encode(serialized), isA<String>());

    // also test a class without @JsonSerializable(explicitToJson: true)
    final n1 = Node(
        id: 1,
        name: 'a',
        children: {Node(id: 2, name: 'a1'), Node(id: 3, name: 'a2')}.asHasMany);
    final s2 = container.nodes.remoteAdapter.serialize(n1);
    expect(s2, {
      'id': 1,
      'name': 'a',
      'children': ['2', '3']
    });
    expect(json.encode(s2), isA<String>());
  });

  test('serialize empty', () async {
    final model = (container.people.remoteAdapter.deserialize(null)).model;
    expect(model, isNull);
    final model2 = (container.people.remoteAdapter.deserialize('')).model;
    expect(model2, isNull);
  });

  test('deserialize multiple', () async {
    final models = (container.people.remoteAdapter.deserialize([
      {'_id': '23', 'name': 'Ko', 'age': 24},
      {'_id': '26', 'name': 'Ze', 'age': 58}
    ])).models;

    expect(models, [
      Person(id: '23', name: 'Ko', age: 24),
      Person(id: '26', name: 'Ze', age: 58)
    ]);
  });

  test('deserialize with BelongsTo id', () async {
    final p = (container.people.remoteAdapter.deserialize([
      {'_id': '1', 'name': 'Na', 'age': 88, 'familia': null}
    ])).model!;

    Familia(id: '1', surname: 'Kong');

    expect(p.familia.key, isNull);

    final p1 = (container.people.remoteAdapter.deserialize([
      {'_id': '27', 'name': 'Ko', 'age': 24, 'familia': '332'}
    ])).model!;

    Familia(id: '332', surname: 'Tao');

    expect(p1.familia.value!.id, '332');

    final p2 = Person(
        id: '27',
        name: 'Ko',
        age: 24,
        familia: Familia(id: '332', surname: 'Tao').asBelongsTo);

    expect(p1, p2);

    expect(p1.familia.value, p2.familia.value);
  });

  test('deserialize returns even if no ID is present', () async {
    final familia = (container.familia.remoteAdapter.deserialize([
      {'surname': 'Ko'}
    ])).model;
    expect(familia, isNotNull);
  });

  test('deserialize with HasMany ids (including nulls)', () async {
    final f = (container.familia.remoteAdapter.deserialize([
      {
        'id': '1',
        'surname': 'Ko',
        'persons': ['1', null, '2']
      }
    ])).model!;

    expect(
        f.persons.keys,
        unorderedEquals([
          graph.getKeyForId('people', '1'),
          graph.getKeyForId('people', '2'),
        ]));
  });

  test('deserialize with embedded relationships', () async {
    final data = container.familia.remoteAdapter.deserialize(
      [
        {
          'id': '1',
          'surname': 'Byrde',
          'persons': <Map<String, dynamic>>[
            {'_id': '1', 'name': 'Wendy', 'age': 58},
            {'_id': '2', 'name': 'Marty', 'age': 60},
          ],
          'cottage_id': <String, dynamic>{
            'id': '1',
            'address': '12345 Long Rd',
          }
        }
      ],
    );

    final f1 = data.model!;
    final f2 = Familia(id: '1', surname: 'Byrde');

    expect(f1, f2);

    final p1 = Person(id: '1', name: 'Wendy', age: 58);
    final p2 = Person(id: '2', name: 'Marty', age: 60);

    // check included instead
    expect(data.included, [p1, p2, House(id: '1', address: '12345 Long Rd')]);

    expect(f1.persons.toSet(), {p1, p2});
    expect(f1.cottage.value, House(id: '1', address: '12345 Long Rd'));
  });

  test('deserialize with nested embedded relationships', () async {
    final data = container.people.remoteAdapter.deserialize(
      [
        {
          '_id': '1',
          'name': 'Marty',
          'familia': <String, dynamic>{
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
      Familia(id: '1', surname: 'Byrde'),
      House(id: '1', address: '123 Main St'),
    ]);
  });

  test('deserializes/serializes with overriden json key for relationship',
      () async {
    BookAuthor(id: 332, name: 'Zhung', books: HasMany());

    final deserialized = container.books.remoteAdapter.deserialize([
      {'id': 27, 'title': 'Ko', 'original_author_id': 332}
    ]);
    final book = deserialized.model;

    expect(book!.originalAuthor!.value!.id, 332);

    expect(container.books.remoteAdapter.serialize(book), {
      'id': 27,
      'title': 'Ko',
      'number_of_sales': 0,
      'original_author_id': '332'
    });
  });
}
