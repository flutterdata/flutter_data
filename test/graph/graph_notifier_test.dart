import 'dart:math';

import 'package:flutter_data/flutter_data.dart';
import 'package:test/test.dart';

import '../_support/family.dart';
import '../_support/house.dart';
import '../_support/person.dart';
import '../_support/setup.dart';

void main() async {
  setUp(setUpFn);

  test('add/remove nodes', () {
    graph.addNode('b1');
    expect(graph.getNode('b1'), isEmpty);
    graph.removeNode('b1');
    expect(graph.getNode('b1'), isNull);
  });

  // test('assertions', () {
  //   expect(() => graph.addNode(null), throwsA(isA<AssertionError>()));
  //   expect(() => graph.getNode(null), throwsA(isA<AssertionError>()));
  //   expect(() => graph.removeNode(null), throwsA(isA<AssertionError>()));
  //   expect(() => graph.addEdges('a:b', tos: null, metadata: 'c:d'),
  //       throwsA(isA<AssertionError>()));
  //   expect(() => graph.removeEdges(null, metadata: 'c:d'),
  //       throwsA(isA<AssertionError>()));
  // });

  test('add/remove edges with metadata', () {
    graph.addNodes(['h1', 'b1', 'b2']);
    graph.addEdges('h1',
        tos: ['b1', 'b2'], metadata: 'blogs', inverseMetadata: 'host');

    expect(graph.getEdge('b1', metadata: 'host'), {'h1'});
    expect(graph.getEdge('h1', metadata: 'blogs'), {'b1', 'b2'});

    graph.removeEdge('h1', 'b2', metadata: 'blogs', inverseMetadata: 'host');

    final _map = graph.toMap();
    expect(_map['h1'], {
      'blogs': {'b1'}
    });
    expect(_map['b1'], {
      'host': {'h1'}
    });

    expect(graph.getEdge('b2', metadata: 'host'), isEmpty);

    graph.addNode('hosts#1');
    graph.addEdge('h1', 'hosts#1', metadata: 'id', inverseMetadata: 'key');
    expect(graph.getEdge('h1', metadata: 'id'), contains('hosts#1'));
    expect(graph.getEdge('hosts#1', metadata: 'key'), contains('h1'));
    // all edges without filtering by metadata
    expect(graph.getNode('h1'), {
      'blogs': {'b1'},
      'id': {'hosts#1'}
    });

    graph.removeEdges('h1', metadata: 'blogs');
    expect(graph.getNode('h1'), {
      'id': {'hosts#1'}
    });
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

  test('deletes a new key', () {
    final key = graph.getKeyForId('people', '1',
        keyIfAbsent: DataHelpers.generateKey<Person>())!;
    expect(graph.getIdForKey(key), '1');
    graph.removeId('people', '1');
    expect(graph.getIdForKey(key), isNull);
  });

  test('does not associate a key when id is null', () {
    var key = graph.getKeyForId('people', null,
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
    graph.getKeyForId('families', '3', keyIfAbsent: 'families#c3c3c3');

    final key = 'families#c3c3c3';
    expect(key, graph.getKeyForId('families', '3'));
  });

  test('two models with id should get the same key', () {
    expect(graph.getKeyForId('families', '2812', keyIfAbsent: 'f1'),
        graph.getKeyForId('families', '2812', keyIfAbsent: 'f1'));
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
        graph.toMap().keys.toSet(),
        containsAll({
          'people#a2a2a2',
          'people#a1a1a1',
          'id:people#a1a1a1',
          'id:people#1'
        }));
    expect(graph.getKeyForId('people', '1'), 'people#a1a1a1');
    graph.removeKey('people#a1a1a1');
    expect(graph.getKeyForId('people', '1'), isNull);
  });

  test('saves key', () async {
    final residence = House(address: '123 Main St').init(container.read);
    final length = 518;
    final div = 19;

    for (var i = 0; i < length; i++) {
      final family = Family(
        id: '$i',
        surname: 'Smith',
        residence: residence.asBelongsTo,
        persons: HasMany(),
      ).init(container.read);

      // add some people
      if (i % div == 0) {
        family.persons
            .add(Person(name: 'new kid #$i', age: i).init(container.read));
      }

      // remove some residence relationships
      if (Random().nextBool()) {
        family.residence!.value = null;
      }

      await family.save();
    }

    expect(graph.toMap().keys.where((k) => k.startsWith('families')),
        hasLength(length));
  });

  test('namespaced keys crud', () {
    // enable namespace assertions for this test
    graph.debugAssert(true);

    expect(() => graph.addNode('superman'), throwsA(isA<AssertionError>()));

    graph.addNode('superman:1');
    expect(graph.getNode('superman:1'), isA<Map<String, List<String>>>());

    expect(
        () =>
            graph.addEdge('superman:1', 'nonamespace', metadata: 'nonamespace'),
        throwsA(isA<AssertionError>()));

    graph.addEdge('superman:1', 'nonamespace', metadata: 'superman:prefix');
    expect(graph.getEdge('superman:1', metadata: 'superman:prefix'),
        containsAll(['nonamespace']));
    graph.removeEdges('superman:1', metadata: 'superman:prefix');
    expect(graph.hasEdge('superman:1', metadata: 'superman:prefix'), false);

    graph.removeNode('superman:1');
    expect(graph.hasNode('superman:1'), isFalse);

    expect(() => graph.addNode('super:man:1'), throwsA(isA<AssertionError>()));
  });

  test('namespace', () {
    expect(StringUtils.namespace('id', StringUtils.typify('posts', 'a9')),
        'id:posts#a9');
    expect(
        StringUtils.namespace('zzz', StringUtils.typify('animals', '278#12')),
        'zzz:animals#278#12');
  });

  test('denamespace', () {
    expect('superman:1'.denamespace(), '1');
    expect('id:posts#a9'.denamespace().detypify(), 'a9');
  });

  test('remove orphans', () {
    graph.addNode('a');
    graph.addNode('b');
    graph.removeOrphanNodes();
    expect(graph.hasNode('a'), isFalse);
    expect(graph.hasNode('b'), isFalse);
  });

  test('event', () {
    final event =
        DataGraphEvent(keys: ['a', 'b'], type: DataGraphEventType.addEdge);
    expect(event.toString(), '[GraphEvent] DataGraphEventType.addEdge: [a, b]');
  });

  test('clear', () {
    graph.addNode('a');
    graph.addNode('b');
    expect(graph.toMap(), isNotEmpty);
    graph.clear();
    expect(graph.toMap(), isEmpty);
  });
}
