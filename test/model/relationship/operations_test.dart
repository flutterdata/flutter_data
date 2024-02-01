import 'package:flutter_data/flutter_data.dart';
import 'package:flutter_data/src/core/edge.dart';
import 'package:test/test.dart';

import '../../_support/setup.dart';

void main() async {
  setUpAll(setUpLocalStorage);
  tearDownAll(tearDownLocalStorage);
  setUp(setUpFn);
  tearDown(tearDownFn);

  test('operations', () async {
    await container.books.writeTxnAsync((store, param) {
      store
          .box<Edge>()
          .put(Edge(from: 'post#1', name: 'comments', to: 'comments#3'));
    }, null);
    final removeOp1 = RemoveEdgeOperation(
        Edge(from: 'post#1', name: 'comments', to: 'comments#3'));
    final addOp1 = AddEdgeOperation(
        Edge(from: 'post#1', name: 'comments', to: 'comments#1'));
    final removeOp2 = RemoveEdgeOperation(
        Edge(from: 'post#2', name: 'comments', to: 'comments#2'));
    final addOps = List.generate(
        20,
        (i) => AddEdgeOperation(
            Edge(from: 'post#2', name: 'comments', to: 'comments#$i')));

    final operations = [removeOp1, addOp1, removeOp2, ...addOps];
    await container.books.writeTxnAsync((store, operations) {
      operations.run(store);
    }, operations);
    expect(core.store.box<Edge>().count(), equals(21)); // 1 + 20
  });
}
