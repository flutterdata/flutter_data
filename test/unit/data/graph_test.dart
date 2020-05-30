import 'package:flutter_data/src/util/graph_notifier.dart';
import 'package:test/test.dart';

void main() async {
  test('add/remove nodes', () {
    final graph = DataGraph();
    graph.addNode('b1');
    expect(graph.getAll('b1'), isEmpty);
    graph.removeNode('b1');
    expect(graph.getAll('b1'), isNull);
  });

  test('add/remove edges with metadata', () {
    final graph = DataGraph();
    graph.add('h1', 'b1', metadata: 'blogs', inverseMetadata: 'host');
    graph.add('h1', 'b2', metadata: 'blogs', inverseMetadata: 'host');

    expect(graph.get('b1', metadata: 'host'), {'h1'});
    expect(graph.get('h1', metadata: 'blogs'), {'b1', 'b2'});

    graph.remove('h1', 'b2');

    expect(graph.get('h1', metadata: 'blogs'), {'b1'});

    graph.add('h1', 'hosts#1', metadata: 'id', inverseMetadata: '_key');
    expect(graph.get('h1', metadata: 'id'), contains('hosts#1'));
    expect(graph.get('hosts#1', metadata: '_key'), contains('h1'));
    // all edges without filtering by metadata
    expect(graph.getAll('h1'), {
      'blogs': {'b1'},
      'id': {'hosts#1'}
    });
  });

  test('serialize/deserialize', () {
    final graph = DataGraph();
    graph.add('h1', 'b1', metadata: 'blogs', inverseMetadata: 'host');
    graph.add('h1', 'b2', metadata: 'blogs', inverseMetadata: 'host');
    graph.add('h1', 'hosts#1', metadata: 'id', inverseMetadata: '_key');

    graph.add('b1', 'p1', metadata: 'posts', inverseMetadata: 'blog');
    graph.add('p2', 'b1', metadata: 'blog', inverseMetadata: 'posts');

    final map = graph.toMap();
    final graph2 = DataGraph.fromMap(map);
    // deserializing a serialized graph should be equal
    expect(map, graph2.toMap());
    // none should contain IDs such as hosts#1
    expect(map.containsKey('hosts#1'), false);
    expect(graph2.toMap().containsKey('hosts#1'), false);

    // but still are present and working in the actual graphs
    expect(graph.get('hosts#1', metadata: '_key'), contains('h1'));
    expect(graph2.get('hosts#1', metadata: '_key'), contains('h1'));
  });
}
