part of flutter_data;

sealed class _EdgeOperation {
  final Edge edge;
  _EdgeOperation(this.edge);
}

class AddEdgeOperation extends _EdgeOperation {
  AddEdgeOperation(super.edge);
}

class RemoveEdgeOperation extends _EdgeOperation {
  RemoveEdgeOperation(super.edge);
}

class RemoveEdgeByIdOperation extends RemoveEdgeOperation {
  // Create empty edge and assign key in this case
  RemoveEdgeByIdOperation(int key) : super(Edge(from: '', name: '', to: '')) {
    super.edge.internalKey = key;
  }
}

class UpdateEdgeOperation extends _EdgeOperation {
  final String newTo;
  UpdateEdgeOperation(super.edge, this.newTo);
}

extension EdgeOperationsX on List<_EdgeOperation> {
  void run(Store store) {
    final box = store.box<Edge>();
    for (final op in this) {
      switch (op) {
        case RemoveEdgeOperation(edge: final edge):
          box.remove(edge.internalKey);
          break;
        case AddEdgeOperation(edge: final edge):
          box.put(edge);
          break;
        case UpdateEdgeOperation(edge: final edge, newTo: final newTo):
          box.remove(edge.internalKey);
          box.put(Edge(
              from: edge.from,
              name: edge.name,
              to: newTo,
              inverseName: edge.inverseName));
          break;
      }
    }
    // final conds =
    //     pairsToRemove.map((r) => Relationship._queryConditionTo(r.$1, r.$2));

    // if (conds.isNotEmpty) {
    //   final cond = conds.reduce((acc, r) => acc | r);
    //   store.box<Edge>().query(cond).build().remove();
    // }

    // store.box<Edge>().putMany(edgesToAdd.toList());
  }
}
