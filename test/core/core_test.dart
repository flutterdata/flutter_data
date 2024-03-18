import 'dart:math';

import 'package:flutter_data/flutter_data.dart';
import 'package:flutter_data/src/core/stored_model.dart';
import 'package:test/test.dart';

import '../_support/book.dart';
import '../_support/familia.dart';
import '../_support/house.dart';
import '../_support/person.dart';
import '../_support/setup.dart';

void main() async {
  setUp(setUpFn);
  tearDown(tearDownFn);

  test('produces a new key deterministically', () {
    var key = core.getKeyForId('people', '1');
    expect(key, equals('people#-3284248607767184521'));
  });

  test('produces a key for empty string', () {
    final key = core.getKeyForId('people', '');
    expect(key, startsWith('people#'));
  });

  test('gets back int id as int, else as string', () {
    final key = core.getKeyForId('libraries', 1);
    final library =
        Library(id: 1, books: HasMany(), name: 'test').init().saveLocal();
    expect(DataModelMixin.keyFor(library), 'libraries#-1061085972839915131');
    // getIdForKey only works when key is persisted
    expect(core.getIdForKey(key), 1);
  });

  test('creates random key when id is null', () {
    final key = core.getKeyForId('people', null);
    expect(core.getIdForKey(key), isNull);
    expect(int.tryParse(key.split('#')[1]), isA<int>());
  });

  test('saves key', () async {
    final residence = House(address: '123 Main St');
    final length = 1000;
    final div = 2;
    final familias = <Familia>[];

    for (var i = 0; i < length; i++) {
      final familia = Familia(
        id: '$i',
        surname: 'Smith',
        residence: residence.asBelongsTo,
        persons: HasMany(),
      );

      // add some people
      if (i % div == 0) {
        familia.persons.add(Person(name: 'new kid #$i', age: i));
      }

      // remove some residence relationships
      if (Random().nextBool()) {
        familia.residence.value = null;
      }

      familias.add(familia);
    }

    await logTime('bulk save', () async {
      await container.familia.remoteAdapter.localAdapter.saveMany(familias);
    });

    expect(container.familia.remoteAdapter.localAdapter.count, length);
  });

  test('namespace', () {
    expect('a9'.typifyWith('posts').namespaceWith('id'), 'id:posts##a9');
    expect('278#12'.typifyWith('animals').namespaceWith('zzz'),
        'zzz:animals##278#12');
  });

  test('denamespace', () {
    expect('superman:1'.denamespace(), '1');
    expect('id:posts##a9'.denamespace().detypify(), 'a9');
  });

  test('event', () {
    final event =
        DataGraphEvent(keys: ['a', 'b'], type: DataGraphEventType.addEdge);
    expect(event.toString(), 'addEdge: [a, b]');
  });
}
