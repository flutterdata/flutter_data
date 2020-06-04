import 'package:flutter_data/src/util/graph_notifier.dart';
import 'package:test/test.dart';

import '../setup.dart';

void main() async {
  DataGraph graph;
  setUp(() {
    graph = DataGraph(FakeBox());
  });

  test('add/remove nodes', () {
    graph.addNode('b1');
    expect(graph.getAll('b1'), isEmpty);
    graph.removeNode('b1');
    expect(graph.getAll('b1'), isNull);
  });

  test('add/remove edges with metadata', () {
    graph.add('h1', 'b1', metadata: 'blogs', inverseMetadata: 'host');
    graph.add('h1', 'b2', metadata: 'blogs', inverseMetadata: 'host');

    expect(graph.getFor('b1', 'host'), {'h1'});
    expect(graph.getFor('h1', 'blogs'), {'b1', 'b2'});

    graph.remove('h1', 'b2');

    expect(graph.getFor('h1', 'blogs'), {'b1'});

    graph.add('h1', 'hosts#1', metadata: 'id', inverseMetadata: '_key');
    expect(graph.getFor('h1', 'id'), contains('hosts#1'));
    expect(graph.getFor('hosts#1', '_key'), contains('h1'));
    // all edges without filtering by metadata
    expect(graph.getAll('h1'), {
      'blogs': {'b1'},
      'id': {'hosts#1'}
    });
  });

  test('serialize/deserialize', () {
    graph.add('h1', 'b1', metadata: 'blogs', inverseMetadata: 'host');
    graph.add('h1', 'b2', metadata: 'blogs', inverseMetadata: 'host');
    graph.add('h1', 'hosts#1', metadata: 'id', inverseMetadata: '_key');

    graph.add('b1', 'p1', metadata: 'posts', inverseMetadata: 'blog');
    graph.add('p2', 'b1', metadata: 'blog', inverseMetadata: 'posts');

    final box = graph.box;
    final graph2 = DataGraph(box);
    // deserializing a serialized graph should be equal
    expect(box.toMap(), graph2.toMap());

    // keys are present in both graphs
    expect(graph.getFor('hosts#1', '_key'), contains('h1'));
    expect(graph2.getFor('hosts#1', '_key'), contains('h1'));
  });
}
