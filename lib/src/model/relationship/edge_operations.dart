part of flutter_data;

sealed class _EdgeOperation {
  final Edge edge;
  _EdgeOperation(this.edge);
  @override
  String toString() {
    return '$runtimeType => $edge';
  }
}

class AddEdgeOperation extends _EdgeOperation {
  AddEdgeOperation(super.edge);
}

class RemoveEdgeOperation extends _EdgeOperation {
  RemoveEdgeOperation(super.edge);
}

class RemoveEdgeByKeyOperation extends RemoveEdgeOperation {
  // Create empty edge and assign key in this case
  RemoveEdgeByKeyOperation(int key) : super(Edge(from: '', name: '', to: '')) {
    super.edge.internalKey = key;
  }
  String toString() {
    return '$runtimeType => [${edge.internalKey}]';
  }
}

class UpdateEdgeOperation extends _EdgeOperation {
  final String newTo;
  UpdateEdgeOperation(super.edge, this.newTo);
}
