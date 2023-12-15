part of flutter_data;

sealed class _KeyOperation {
  String key;
  _KeyOperation(this.key);
}

class AddKeyOperation extends _KeyOperation {
  String typeId;
  AddKeyOperation(super.key, this.typeId);
}

class RemoveKeyOperation extends _KeyOperation {
  RemoveKeyOperation(super.key);
}

sealed class _EdgeOperation {
  String from;
  String name;
  _EdgeOperation(this.from, this.name);
}

class AddEdgeOperation extends _EdgeOperation {
  final String to;
  final String? inverseName;
  AddEdgeOperation(super.from, super.name, this.to, [this.inverseName]);
}

class RemoveEdgeOperation extends _EdgeOperation {
  final String? to;
  RemoveEdgeOperation(super.from, super.name, [this.to]);
}

class UpdateEdgeOperation extends _EdgeOperation {
  final String to;
  final String newTo;
  UpdateEdgeOperation(super.from, super.name, this.to, this.newTo);
}

extension EdgeOperationsX on List<_EdgeOperation> {
  void run(Store store) {
    final pairsToRemove = <(String, String)>{};
    final edgesToAdd = <Edge>{};
    for (final op in this) {
      switch (op) {
        case RemoveEdgeOperation(from: final from, name: final name, to: null):
          pairsToRemove.add((from, name));
          break;
        case AddEdgeOperation(
            from: final from,
            name: final name,
            to: final to,
            inverseName: final inverseName
          ):
          edgesToAdd.add(
              Edge(from: from, name: name, to: to, inverseName: inverseName));
          break;
        default:
      }
    }
    final conds =
        pairsToRemove.map((r) => Relationship._queryConditionTo(r.$1, r.$2));

    if (conds.isNotEmpty) {
      final cond = conds.reduce((acc, r) => acc | r);
      store.box<Edge>().query(cond).build().remove();
    }
    store.box<Edge>().putMany(edgesToAdd.toList());
  }
}
