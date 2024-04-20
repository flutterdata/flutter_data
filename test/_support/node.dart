import 'package:equatable/equatable.dart';
import 'package:flutter_data/flutter_data.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'node.freezed.dart';
part 'node.g.dart';

@freezed
@DataAdapter([NodeAdapter, NodeLocalAdapter], remote: false)
class Node extends DataModel<Node> with EquatableMixin, _$Node {
  Node._();
  factory Node(
      {int? id,
      String? name,
      @DataRelationship(inverse: 'children') BelongsTo<Node>? parent,
      @DataRelationship(inverse: 'parent') HasMany<Node>? children}) = _Node;
  factory Node.fromJson(Map<String, dynamic> json) => _$NodeFromJson(json);

  @override
  List<Object?> get props => [id, name, parent, children];
}

mixin NodeAdapter on Adapter<Node> {
  @override
  void onModelInitialized(Node model) {
    model.saveLocal();
  }
}

mixin NodeLocalAdapter on Adapter<Node> {
  @override
  Node deserialize(Map<String, dynamic> map, {String? key}) {
    if (map['name'] == 'node') {
      map['name'] = 'local';
    }
    return super.deserialize(map, key: key);
  }
}
