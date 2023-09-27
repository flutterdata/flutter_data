import 'package:flutter_data/flutter_data.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'node.freezed.dart';
part 'node.g.dart';

@freezed
@DataRepository([NodeAdapter], localAdapters: [NodeLocalAdapter], remote: false)
class Node extends DataModel<Node> with _$Node {
  Node._();
  factory Node(
      {int? id,
      String? name,
      @DataRelationship(inverse: 'children') BelongsTo<Node>? parent,
      @DataRelationship(inverse: 'parent') HasMany<Node>? children}) = _Node;
  factory Node.fromJson(Map<String, dynamic> json) => _$NodeFromJson(json);
}

mixin NodeAdapter on RemoteAdapter<Node> {
  @override
  void onModelInitialized(Node model) => model.saveLocal();
}

mixin NodeLocalAdapter on LocalAdapter<Node> {
  @override
  Node deserialize(Map<String, dynamic> map) {
    if (map['name'] == 'node') {
      map['name'] = 'local';
    }
    return super.deserialize(map);
  }
}
