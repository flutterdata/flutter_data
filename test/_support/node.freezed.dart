// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies

part of 'node.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;
Node _$NodeFromJson(Map<String, dynamic> json) {
  return _Node.fromJson(json);
}

/// @nodoc
class _$NodeTearOff {
  const _$NodeTearOff();

// ignore: unused_element
  _Node call(
      {int id,
      String name,
      @DataRelationship(inverse: 'children') BelongsTo<Node> parent,
      @DataRelationship(inverse: 'parent') HasMany<Node> children}) {
    return _Node(
      id: id,
      name: name,
      parent: parent,
      children: children,
    );
  }

// ignore: unused_element
  Node fromJson(Map<String, Object> json) {
    return Node.fromJson(json);
  }
}

/// @nodoc
// ignore: unused_element
const $Node = _$NodeTearOff();

/// @nodoc
mixin _$Node {
  int get id;
  String get name;
  @DataRelationship(inverse: 'children')
  BelongsTo<Node> get parent;
  @DataRelationship(inverse: 'parent')
  HasMany<Node> get children;

  Map<String, dynamic> toJson();
  $NodeCopyWith<Node> get copyWith;
}

/// @nodoc
abstract class $NodeCopyWith<$Res> {
  factory $NodeCopyWith(Node value, $Res Function(Node) then) =
      _$NodeCopyWithImpl<$Res>;
  $Res call(
      {int id,
      String name,
      @DataRelationship(inverse: 'children') BelongsTo<Node> parent,
      @DataRelationship(inverse: 'parent') HasMany<Node> children});
}

/// @nodoc
class _$NodeCopyWithImpl<$Res> implements $NodeCopyWith<$Res> {
  _$NodeCopyWithImpl(this._value, this._then);

  final Node _value;
  // ignore: unused_field
  final $Res Function(Node) _then;

  @override
  $Res call({
    Object id = freezed,
    Object name = freezed,
    Object parent = freezed,
    Object children = freezed,
  }) {
    return _then(_value.copyWith(
      id: id == freezed ? _value.id : id as int,
      name: name == freezed ? _value.name : name as String,
      parent: parent == freezed ? _value.parent : parent as BelongsTo<Node>,
      children:
          children == freezed ? _value.children : children as HasMany<Node>,
    ));
  }
}

/// @nodoc
abstract class _$NodeCopyWith<$Res> implements $NodeCopyWith<$Res> {
  factory _$NodeCopyWith(_Node value, $Res Function(_Node) then) =
      __$NodeCopyWithImpl<$Res>;
  @override
  $Res call(
      {int id,
      String name,
      @DataRelationship(inverse: 'children') BelongsTo<Node> parent,
      @DataRelationship(inverse: 'parent') HasMany<Node> children});
}

/// @nodoc
class __$NodeCopyWithImpl<$Res> extends _$NodeCopyWithImpl<$Res>
    implements _$NodeCopyWith<$Res> {
  __$NodeCopyWithImpl(_Node _value, $Res Function(_Node) _then)
      : super(_value, (v) => _then(v as _Node));

  @override
  _Node get _value => super._value as _Node;

  @override
  $Res call({
    Object id = freezed,
    Object name = freezed,
    Object parent = freezed,
    Object children = freezed,
  }) {
    return _then(_Node(
      id: id == freezed ? _value.id : id as int,
      name: name == freezed ? _value.name : name as String,
      parent: parent == freezed ? _value.parent : parent as BelongsTo<Node>,
      children:
          children == freezed ? _value.children : children as HasMany<Node>,
    ));
  }
}

@JsonSerializable()

/// @nodoc
class _$_Node extends _Node {
  _$_Node(
      {this.id,
      this.name,
      @DataRelationship(inverse: 'children') this.parent,
      @DataRelationship(inverse: 'parent') this.children})
      : super._();

  factory _$_Node.fromJson(Map<String, dynamic> json) =>
      _$_$_NodeFromJson(json);

  @override
  final int id;
  @override
  final String name;
  @override
  @DataRelationship(inverse: 'children')
  final BelongsTo<Node> parent;
  @override
  @DataRelationship(inverse: 'parent')
  final HasMany<Node> children;

  @override
  String toString() {
    return 'Node(id: $id, name: $name, parent: $parent, children: $children)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _Node &&
            (identical(other.id, id) ||
                const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.name, name) ||
                const DeepCollectionEquality().equals(other.name, name)) &&
            (identical(other.parent, parent) ||
                const DeepCollectionEquality().equals(other.parent, parent)) &&
            (identical(other.children, children) ||
                const DeepCollectionEquality()
                    .equals(other.children, children)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(name) ^
      const DeepCollectionEquality().hash(parent) ^
      const DeepCollectionEquality().hash(children);

  @override
  _$NodeCopyWith<_Node> get copyWith =>
      __$NodeCopyWithImpl<_Node>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$_$_NodeToJson(this);
  }
}

abstract class _Node extends Node {
  _Node._() : super._();
  factory _Node(
      {int id,
      String name,
      @DataRelationship(inverse: 'children') BelongsTo<Node> parent,
      @DataRelationship(inverse: 'parent') HasMany<Node> children}) = _$_Node;

  factory _Node.fromJson(Map<String, dynamic> json) = _$_Node.fromJson;

  @override
  int get id;
  @override
  String get name;
  @override
  @DataRelationship(inverse: 'children')
  BelongsTo<Node> get parent;
  @override
  @DataRelationship(inverse: 'parent')
  HasMany<Node> get children;
  @override
  _$NodeCopyWith<_Node> get copyWith;
}
