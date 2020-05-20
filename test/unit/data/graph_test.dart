import 'package:flutter_data/src/util/graph_notifier.dart';
import 'package:test/test.dart';

void main() async {
  test('add/remove bidirectional edges', () {
    final graph = DataGraph();
    graph.add('b1', 'h1');
    graph.add('p1', 'b1');
    expect(graph.edgesFrom('b1'), containsAll(['h1', 'p1']));
    expect(graph.edgesFrom('h1'), contains('b1'));

    graph.remove('h1', 'b1');
    expect(graph.edgesFrom('h1'), isEmpty);
    expect(graph.edgesFrom('b1'), contains('p1'));
  });

  test('add/remove nodes', () {
    final graph = DataGraph();
    graph.addNode('b1');
    expect(graph.edgesFrom('b1'), isEmpty);
    graph.removeNode('b1');
    expect(graph.edgesFrom('b1'), isNull);
  });

  test('add/remove edges with metadata and serialize/deserialize', () {
    final graph = DataGraph();
    graph.add('h1', 'b1', fromMetadata: 'blogs', toMetadata: 'host');
    graph.add('b2', 'h1', fromMetadata: 'host', toMetadata: 'blogs');
    expect(graph.edgesFrom('b1', 'host'), contains('h1'));
    expect(graph.edgesFrom('h1', 'blogs'), hasLength(2));

    graph.add('h1', 'hosts#1', fromMetadata: 'id', toMetadata: '_key');
    expect(graph.edgesFrom('h1', 'id'), contains('hosts#1'));
    expect(graph.edgesFrom('hosts#1', '_key'), contains('h1'));
    // all edges without filtering by metadata
    expect(graph.edgesFrom('h1'), hasLength(3));
  });

  test('serialize/deserialize', () {
    final graph = DataGraph();
    graph.add('h1', 'b1', fromMetadata: 'blogs', toMetadata: 'host');
    graph.add('b2', 'h1', fromMetadata: 'host', toMetadata: 'blogs');
    graph.add('h1', 'hosts#1', fromMetadata: 'id', toMetadata: '_key');

    graph.add('b1', 'p1', fromMetadata: 'posts', toMetadata: 'blog');
    graph.add('b1', 'p2', fromMetadata: 'posts', toMetadata: 'blog');

    final map = graph.toMap();
    final graph2 = DataGraph.fromMap(map);
    // deserializing a serialized graph should be equal
    expect(map, graph2.toMap());
    // none should contain IDs such as hosts#1
    expect(map.containsKey('hosts#1'), false);
    expect(graph2.toMap().containsKey('hosts#1'), false);

    // but still are present and working in the actual graphs
    expect(graph.edgesFrom('hosts#1', '_key'), contains('h1'));
    expect(graph2.edgesFrom('hosts#1', '_key'), contains('h1'));
  });
}
