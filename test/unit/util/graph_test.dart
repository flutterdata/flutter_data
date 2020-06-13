import 'package:flutter_data/src/util/graph_notifier.dart';
import 'package:test/test.dart';

import '../setup.dart';

void main() async {
  DataGraphNotifier graph;
  setUp(() {
    graph = DataGraphNotifier(FakeBox());
  });

  test('add/remove nodes', () {
    graph.addNode('b1');
    expect(graph.getNode('b1'), isEmpty);
    graph.removeNode('b1');
    expect(graph.getNode('b1'), isNull);
  });

  test('add/remove edges with metadata', () {
    graph.addNode('h1');
    graph.addNode('b1');
    graph.addNode('b2');
    graph.addEdge('h1', 'b1', metadata: 'blogs', inverseMetadata: 'host');
    graph.addEdge('h1', 'b2', metadata: 'blogs', inverseMetadata: 'host');

    expect(graph.getEdge('b1', metadata: 'host'), {'h1'});
    expect(graph.getEdge('h1', metadata: 'blogs'), {'b1', 'b2'});

    graph.removeEdge('h1', 'b2', metadata: 'blogs');

    expect(graph.getEdge('h1', metadata: 'blogs'), {'b1'});

    graph.addNode('hosts#1');
    graph.addEdge('h1', 'hosts#1', metadata: 'id', inverseMetadata: 'key');
    expect(graph.getEdge('h1', metadata: 'id'), contains('hosts#1'));
    expect(graph.getEdge('hosts#1', metadata: 'key'), contains('h1'));
    // all edges without filtering by metadata
    expect(graph.getNode('h1'), {
      'blogs': {'b1'},
      'id': {'hosts#1'}
    });
  });

  test('serialize/deserialize', () {
    graph.addNode('h1');
    graph.addNode('b1');
    graph.addNode('b2');
    graph.addNode('hosts#1');

    graph.addEdge('h1', 'b1', metadata: 'blogs', inverseMetadata: 'host');
    graph.addEdge('h1', 'b2', metadata: 'blogs', inverseMetadata: 'host');
    graph.addEdge('h1', 'hosts#1', metadata: 'id', inverseMetadata: 'key');

    graph.addNode('p1');
    graph.addNode('p2');
    graph.addEdge('b1', 'p1', metadata: 'posts', inverseMetadata: 'blog');
    graph.addEdge('p2', 'b1', metadata: 'blog', inverseMetadata: 'posts');

    final box = graph.box;
    final graph2 = DataGraphNotifier(box);
    // deserializing a serialized graph should be equal
    expect(box.toMap(), graph2.toMap());

    // keys are present in both graphs
    expect(graph.getEdge('hosts#1', metadata: 'key'), contains('h1'));
    expect(graph2.getEdge('hosts#1', metadata: 'key'), contains('h1'));
  });
}
