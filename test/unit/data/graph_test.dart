import 'package:flutter_data/src/util/graph_notifier.dart';
import 'package:test/test.dart';

void main() async {
  test('add/remove bidirectional edges', () {
    final graph = DataGraph();
    graph.addEdge('b1', 'h1');
    graph.addEdge('p1', 'b1');
    expect(graph.edgesFrom('b1'), containsAll(['h1', 'p1']));
    expect(graph.edgesFrom('h1'), contains('b1'));

    graph.removeEdge('h1', 'b1');
    expect(graph.edgesFrom('h1'), isEmpty);
    expect(graph.edgesFrom('b1'), contains('p1'));
  });

  test('add/remove edges with metadata and serialize/deserialize', () {
    final graph = DataGraph();
    graph.addEdge('h1', 'b1', metadata: 'blogs', inverseMetadata: 'host');
    graph.addEdge('b2', 'h1', metadata: 'host', inverseMetadata: 'blogs');
    expect(graph.edgesFrom('b1', 'host'), contains('h1'));
    expect(graph.edgesFrom('h1', 'blogs'), hasLength(2));

    graph.addEdge('h1', 'hosts#1', metadata: 'id', inverseMetadata: '_key');
    expect(graph.edgesFrom('h1', 'id'), contains('hosts#1'));
    expect(graph.edgesFrom('hosts#1', '_key'), contains('h1'));
    // all edges without filtering by metadata
    expect(graph.edgesFrom('h1'), hasLength(3));
  });

  test('serialize/deserialize', () {
    final graph = DataGraph();
    graph.addEdge('h1', 'b1', metadata: 'blogs', inverseMetadata: 'host');
    graph.addEdge('b2', 'h1', metadata: 'host', inverseMetadata: 'blogs');
    graph.addEdge('h1', 'hosts#1', metadata: 'id', inverseMetadata: '_key');

    graph.addEdge('b1', 'p1', metadata: 'posts', inverseMetadata: 'blog');
    graph.addEdge('b1', 'p2', metadata: 'posts', inverseMetadata: 'blog');

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
