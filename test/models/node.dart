import 'package:freezed_annotation/freezed_annotation.dart';

part 'node.freezed.dart';

@freezed
abstract class Node with _$Node {
  factory Node({String name, Node parent}) = _Node;
}
