import 'dart:math';

import 'package:flutter_data/flutter_data.dart';
import 'package:test/test.dart';

import '../_support/familia.dart';
import '../_support/house.dart';
import '../_support/person.dart';
import '../_support/setup.dart';

void main() async {
  setUpAll(setUpLocalStorage);
  tearDownAll(tearDownLocalStorage);
  setUp(setUpFn);
  tearDown(tearDownFn);

  test('produces a new key', () {
    var key = core.getKeyForId('people', '1');
    expect(key, isNull);
    key = core.getKeyForId('people', '1',
        keyIfAbsent: DataHelpers.generateKey<Person>());
    expect(key, startsWith('people#'));
  });

  test('produces a key for empty string', () {
    final key = core.getKeyForId('people', '',
        keyIfAbsent: DataHelpers.generateKey<Person>());
    expect(key, startsWith('people#'));
  });

  test('gets back int id as int, else as string', () {
    final key = core.getKeyForId('people', 1,
        keyIfAbsent: DataHelpers.generateKey<Person>())!;
    expect(core.getIdForKey(key), 1);

    final now = DateTime.now();
    final stringMillis = now.millisecondsSinceEpoch.toString();
    final key2 = core.getKeyForId('people', stringMillis,
        keyIfAbsent: DataHelpers.generateKey<Person>())!;
    expect(core.getIdForKey(key2), stringMillis);
  });

  test('deletes a new key', () {
    final key = core.getKeyForId('people', '1',
        keyIfAbsent: DataHelpers.generateKey<Person>())!;
    expect(core.getIdForKey(key), '1');
    core.removeIdForKey(key);
    expect(core.getIdForKey(key), isNull);
  });

  test('does not associate a key when id is null', () {
    final key = core.getKeyForId('people', null,
        keyIfAbsent: DataHelpers.generateKey<Person>())!;
    expect(core.getIdForKey(key), isNull);
  });

  test('reuses a provided key', () {
    final key = core.getKeyForId('people', '29', keyIfAbsent: 'people#178926')!;
    expect(key, 'people#178926');
    expect(core.getIdForKey(key), '29');
  });

  test('reassign a key', () {
    final key = core.getKeyForId('people', '1', keyIfAbsent: 'people#222')!;
    expect(key, 'people#222');

    core.getKeyForId('people', '2', keyIfAbsent: 'people#222');
    expect(core.getIdForKey(key), '2');
  });

  test('by keys', () {
    // including ids that contain '#' (also used in internal format)
    core.getKeyForId('people', 'p#1', keyIfAbsent: 'people#111');
    core.getKeyForId('people', '2', keyIfAbsent: 'people#222');
    core.getKeyForId('people', '3', keyIfAbsent: 'people#333');

    final ids =
        ['people#111', 'people#222', 'people#333'].map(core.getIdForKey);
    expect(ids, ['p#1', '2', '3']);
  });

  test('by key', () {
    final key = 'familia#333';
    core.getKeyForId('familia', '3', keyIfAbsent: key);
    expect(core.getKeyForId('familia', '3'), key);
  });

  test('two models with id should get the same key', () {
    expect(core.getKeyForId('familia', '2812', keyIfAbsent: 'familia#19'),
        core.getKeyForId('familia', '2812'));
  });

  test('should prioritize ID', () {
    final key = core.getKeyForId('people', '772',
        keyIfAbsent: DataHelpers.generateKey<Person>());

    final randomNewKey = DataHelpers.generateKey<Person>();

    // we are telling manager to reuse the existing key
    // BUT a key for id=772 already exists, so that one will precede
    final finalKey =
        core.getKeyForId('people', '772', keyIfAbsent: randomNewKey);

    expect(finalKey, isNot(randomNewKey));
    expect(key, finalKey);
  });

  test('keys and IDs do not clash', () {
    core.getKeyForId('people', 1, keyIfAbsent: 'people#111');
    core.getKeyForId('people', '111', keyIfAbsent: 'people#222');
    expect(core.getKeyForId('people', '111'), 'people#222');

    final map = core.toIdMap();
    expect(map.keys.toSet(), containsAll({'people#222', 'people#111'}));
    // # separates integers, ## separates strings
    expect(map.values.toSet(), containsAll({'people##111', 'people#1'}));

    expect(core.getKeyForId('people', 1), 'people#111');
  });

  test('saves key', () async {
    final residence = House(address: '123 Main St');
    final length = 100;
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

    // TODO FIX
    // expect(core.toMap().keys.where((k) => k.startsWith('familia')),
    //     hasLength(length));
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
