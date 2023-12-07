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
    var key = graph.getKeyForId('people', '1');
    expect(key, isNull);
    key = graph.getKeyForId('people', '1',
        keyIfAbsent: DataHelpers.generateKey<Person>());
    expect(key, startsWith('people#'));
  });

  test('produces a key for empty string', () {
    final key = graph.getKeyForId('people', '',
        keyIfAbsent: DataHelpers.generateKey<Person>());
    expect(key, startsWith('people#'));
  });

  test('gets back int id as int, else as string', () {
    final key = graph.getKeyForId('people', 1,
        keyIfAbsent: DataHelpers.generateKey<Person>())!;
    expect(graph.getIdForKey(key), 1);

    final now = DateTime.now();
    final stringMillis = now.millisecondsSinceEpoch.toString();
    final key2 = graph.getKeyForId('people', stringMillis,
        keyIfAbsent: DataHelpers.generateKey<Person>())!;
    expect(graph.getIdForKey(key2), stringMillis);
  });

  test('deletes a new key', () {
    final key = graph.getKeyForId('people', '1',
        keyIfAbsent: DataHelpers.generateKey<Person>())!;
    expect(graph.getIdForKey(key), '1');
    graph.removeIdForKey(key);
    expect(graph.getIdForKey(key), isNull);
  });

  test('does not associate a key when id is null', () {
    final key = graph.getKeyForId('people', null,
        keyIfAbsent: DataHelpers.generateKey<Person>())!;
    expect(graph.getIdForKey(key), isNull);
  });

  test('reuses a provided key', () {
    final key =
        graph.getKeyForId('people', '29', keyIfAbsent: 'people#178926')!;
    expect(key, 'people#178926');
    expect(graph.getIdForKey(key), '29');
  });

  test('reassign a key', () {
    final key = graph.getKeyForId('people', '1', keyIfAbsent: 'people#222')!;
    expect(key, 'people#222');

    graph.getKeyForId('people', '2', keyIfAbsent: 'people#222');
    expect(graph.getIdForKey(key), '2');
  });

  test('by keys', () {
    // including ids that contain '#' (also used in internal format)
    graph.getKeyForId('people', 'p#1', keyIfAbsent: 'people#111');
    graph.getKeyForId('people', '2', keyIfAbsent: 'people#222');
    graph.getKeyForId('people', '3', keyIfAbsent: 'people#333');

    final ids =
        ['people#111', 'people#222', 'people#333'].map(graph.getIdForKey);
    expect(ids, ['p#1', '2', '3']);
  });

  test('by key', () {
    final key = 'familia#333';
    graph.getKeyForId('familia', '3', keyIfAbsent: key);
    expect(graph.getKeyForId('familia', '3'), key);
  });

  test('two models with id should get the same key', () {
    expect(graph.getKeyForId('familia', '2812', keyIfAbsent: 'familia#19'),
        graph.getKeyForId('familia', '2812'));
  });

  test('should prioritize ID', () {
    final key = graph.getKeyForId('people', '772',
        keyIfAbsent: DataHelpers.generateKey<Person>());

    final randomNewKey = DataHelpers.generateKey<Person>();

    // we are telling manager to reuse the existing key
    // BUT a key for id=772 already exists, so that one will precede
    final finalKey =
        graph.getKeyForId('people', '772', keyIfAbsent: randomNewKey);

    expect(finalKey, isNot(randomNewKey));
    expect(key, finalKey);
  });

  test('keys and IDs do not clash', () {
    graph.getKeyForId('people', 1, keyIfAbsent: 'people#111');
    graph.getKeyForId('people', '111', keyIfAbsent: 'people#222');
    expect(graph.getKeyForId('people', '111'), 'people#222');

    final map = graph.toIdMap();
    expect(map.keys.toSet(), containsAll({'people#222', 'people#111'}));
    // # separates integers, ## separates strings
    expect(map.values.toSet(), containsAll({'people##111', 'people#1'}));

    expect(graph.getKeyForId('people', 1), 'people#111');
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
    // expect(graph.toMap().keys.where((k) => k.startsWith('familia')),
    //     hasLength(length));
  });

  test('namespaced keys crud', () {
    // enable namespace assertions for this test
    // graph.debugAssert(true);

    // expect(
    //     () =>
    //         graph.addEdge('superman:1', 'superman:to', metadata: 'nonamespace'),
    //     throwsA(isA<AssertionError>()));
    // expect(() => graph.addEdge('superman:1', 'to', metadata: 'superman:prefix'),
    //     throwsA(isA<AssertionError>()));

    // graph.addEdge('superman:1', 'superman:to', metadata: 'superman:prefix');
    // expect(graph.getEdge('superman:1', metadata: 'superman:prefix'),
    //     containsAll(['superman:to']));
    // graph.removeEdges('superman:1', metadata: 'superman:prefix');
    // expect(graph.hasEdge('superman:1', metadata: 'superman:prefix'), false);
    // expect(graph.hasNode('superman:to'), false);
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

  test('clear', () {
    // graph.addEdges('h1',
    //     tos: List.generate(100, (i) => '${i}b').toSet(), metadata: 'host');
    // expect(graph.toMap(), isNotEmpty);
    // graph.clear();
    // expect(graph.toMap(), isEmpty);
  });
}
