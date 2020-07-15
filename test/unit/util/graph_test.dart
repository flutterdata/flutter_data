import 'package:test/test.dart';

import '../setup.dart';

void main() async {
  setUp(setUpFn);

  test('add/remove nodes', () {
    graph.addNode('b1');
    expect(graph.getNode('b1'), isEmpty);
    graph.removeNode('b1');
    expect(graph.getNode('b1'), isNull);
  });

  test('add/remove edges with metadata', () {
    graph.addNodes(['h1', 'b1', 'b2']);
    graph.addEdges('h1',
        tos: ['b1', 'b2'], metadata: 'blogs', inverseMetadata: 'host');

    expect(graph.getEdge('b1', metadata: 'host'), {'h1'});
    expect(graph.getEdge('h1', metadata: 'blogs'), {'b1', 'b2'});

    graph.removeEdge('h1', 'b2', metadata: 'blogs', inverseMetadata: 'host');

    expect(graph.dumpGraph(), {
      'h1': {
        'blogs': {'b1'}
      },
      'b1': {
        'host': {'h1'}
      }
    });

    expect(graph.getEdge('b2', metadata: 'host'), isNull);

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
}
