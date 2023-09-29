import 'dart:math';

import 'package:flutter_data/flutter_data.dart';
import 'package:test/test.dart';

import '../_support/familia.dart';
import '../_support/house.dart';
import '../_support/person.dart';
import '../_support/setup.dart';

void main() async {
  setUpAll(setUpIsar);
  tearDownAll(tearDownIsar);
  setUp(setUpFn);
  tearDown(tearDownFn);

  test('add/remove edges with metadata', () {
    graph.addEdges('h1',
        tos: {'b1', 'b2'}, metadata: 'blogs', inverseMetadata: 'host');

    expect(graph.getEdge('b1', metadata: 'host'), {'h1'});
    expect(graph.getEdge('h1', metadata: 'blogs'), {'b1', 'b2'});

    graph.removeEdge('h1', 'b2', metadata: 'blogs', inverseMetadata: 'host');

    expect(graph.getEdge('h1', metadata: 'blogs'), {'b1'});
    expect(graph.getEdge('b2', metadata: 'host'), isEmpty);

    final map = graph.toMap();
    expect(
      map,
      {
        'h1': {
          'blogs': ['b1']
        },
        'b1': {
          'host': ['h1']
        }
      },
    );

    graph.addEdge('h1', 'hosts#1', metadata: 'id', inverseMetadata: 'key');
    expect(graph.getEdge('h1', metadata: 'id'), contains('hosts#1'));
    expect(graph.getEdge('hosts#1', metadata: 'key'), contains('h1'));
    // all edges without filtering by metadata
    expect(graph.getNode('h1'), {
      'blogs': {'b1'},
      'id': {'hosts#1'}
    });

    graph.removeEdges('h1', metadata: 'blogs');
    expect(graph.getEdge('hosts#1', metadata: 'blogs'), isEmpty);
    expect(graph.getNode('h1'), {
      'id': {'hosts#1'}
    });
  });

  test('addNode/orAdd', () {
    graph.addEdges('h1',
        tos: {'b1', 'b2'}, metadata: 'blogs', inverseMetadata: 'host');
    expect(graph.getEdge('h1', metadata: 'blogs'), hasLength(2));
  });

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

    final dateTime = DateTime.now();
    final key2 = graph.getKeyForId('people', dateTime,
        keyIfAbsent: DataHelpers.generateKey<Person>())!;
    expect(graph.getIdForKey(key2), dateTime.toString());
  });

  test('deletes a new key', () {
    final key = graph.getKeyForId('people', '1',
        keyIfAbsent: DataHelpers.generateKey<Person>())!;
    expect(graph.getIdForKey(key), '1');
    graph.removeId('people', '1');
    expect(graph.getIdForKey(key), isNull);
  });

  test('does not associate a key when id is null', () {
    final key = graph.getKeyForId('people', null,
        keyIfAbsent: DataHelpers.generateKey<Person>())!;
    expect(graph.getIdForKey(key), isNull);
  });

  test('reuses a provided key', () {
    final key =
        graph.getKeyForId('people', '29', keyIfAbsent: 'people#78a92b')!;
    expect(key, 'people#78a92b');
    expect(graph.getIdForKey(key), '29');
  });

  test('reassign a key', () {
    final key = graph.getKeyForId('people', '1', keyIfAbsent: 'people#a5a5a5')!;
    expect(key, 'people#a5a5a5');

    graph.getKeyForId('people', '2', keyIfAbsent: 'people#a5a5a5');
    expect(graph.getIdForKey(key), '2');
  });

  test('by keys', () {
    // including ids that contain '#' (also used in internal format)
    graph.getKeyForId('people', 'p#1', keyIfAbsent: 'people#a1a1a1');
    graph.getKeyForId('people', '2', keyIfAbsent: 'people#b2b2b2');
    graph.getKeyForId('people', '3', keyIfAbsent: 'people#c3c3c3');

    final ids = ['people#a1a1a1', 'people#b2b2b2', 'people#c3c3c3']
        .map(graph.getIdForKey);
    expect(ids, ['p#1', '2', '3']);
  });

  test('by key', () {
    graph.getKeyForId('familia', '3', keyIfAbsent: 'familia#c3c3c3');

    final key = 'familia#c3c3c3';
    expect(key, graph.getKeyForId('familia', '3'));
  });

  test('two models with id should get the same key', () {
    expect(graph.getKeyForId('familia', '2812', keyIfAbsent: 'f1'),
        graph.getKeyForId('familia', '2812', keyIfAbsent: 'f1'));
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
    graph.getKeyForId('people', '1', keyIfAbsent: 'people#a1a1a1');
    graph.getKeyForId('people', 'a1a1a1', keyIfAbsent: 'people#a2a2a2');
    expect(graph.getKeyForId('people', 'a1a1a1'), 'people#a2a2a2');
    expect(
        graph.toIdMap().keys.toSet(),
        containsAll({
          'people#a2a2a2',
          'people#a1a1a1',
        }));

    expect(graph.toIdMap().values.toSet(),
        containsAll({'people#a1a1a1', 'people#1'}));

    expect(graph.getKeyForId('people', '1'), 'people#a1a1a1');
    graph.removeKey('people#a1a1a1');
    expect(graph.getKeyForId('people', '1'), isNull);
  });

  test('saves key', () async {
    final residence = House(address: '123 Main St');
    final length = 100;
    final div = 19;

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

      await familia.save();
    }

    expect(graph.toMap().keys.where((k) => k.startsWith('familia')),
        hasLength(length));
  });

  test('namespaced keys crud', () {
    // enable namespace assertions for this test
    graph.debugAssert(true);

    expect(
        () =>
            graph.addEdge('superman:1', 'superman:to', metadata: 'nonamespace'),
        throwsA(isA<AssertionError>()));
    expect(() => graph.addEdge('superman:1', 'to', metadata: 'superman:prefix'),
        throwsA(isA<AssertionError>()));

    graph.addEdge('superman:1', 'superman:to', metadata: 'superman:prefix');
    expect(graph.getEdge('superman:1', metadata: 'superman:prefix'),
        containsAll(['superman:to']));
    graph.removeEdges('superman:1', metadata: 'superman:prefix');
    expect(graph.hasEdge('superman:1', metadata: 'superman:prefix'), false);
    expect(graph.hasNode('superman:to'), false);
  });

  test('namespace', () {
    expect('a9'.typifyWith('posts').namespaceWith('id'), 'id:posts#a9');
    expect('278#12'.typifyWith('animals').namespaceWith('zzz'),
        'zzz:animals#278#12');
  });

  test('denamespace', () {
    expect('superman:1'.denamespace(), '1');
    expect('id:posts#a9'.denamespace().detypify(), 'a9');
  });

  test('event', () {
    final event =
        DataGraphEvent(keys: ['a', 'b'], type: DataGraphEventType.addEdge);
    expect(event.toString(), 'addEdge: [a, b]');
  });

  test('clear', () {
    for (final i in List.generate(100, (i) => i)) {
      graph.addEdge('b$i', 'h1', metadata: 'host');
    }
    expect(graph.toMap(), isNotEmpty);
    graph.clear();
    expect(graph.toMap(), isEmpty);
  });
}
