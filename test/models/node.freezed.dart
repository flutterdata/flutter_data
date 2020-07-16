// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies

part of 'node.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

class _$NodeTearOff {
  const _$NodeTearOff();

// ignore: unused_element
  _Node call({String name, Node parent}) {
    return _Node(
      name: name,
      parent: parent,
    );
  }
}

// ignore: unused_element
const $Node = _$NodeTearOff();

mixin _$Node {
  String get name;
  Node get parent;

  $NodeCopyWith<Node> get copyWith;
}

abstract class $NodeCopyWith<$Res> {
  factory $NodeCopyWith(Node value, $Res Function(Node) then) =
      _$NodeCopyWithImpl<$Res>;
  $Res call({String name, Node parent});
}

class _$NodeCopyWithImpl<$Res> implements $NodeCopyWith<$Res> {
  _$NodeCopyWithImpl(this._value, this._then);

  final Node _value;
  // ignore: unused_field
  final $Res Function(Node) _then;

  @override
  $Res call({
    Object name = freezed,
    Object parent = freezed,
  }) {
    return _then(_value.copyWith(
      name: name == freezed ? _value.name : name as String,
      parent: parent == freezed ? _value.parent : parent as Node,
    ));
  }
}

abstract class _$NodeCopyWith<$Res> implements $NodeCopyWith<$Res> {
  factory _$NodeCopyWith(_Node value, $Res Function(_Node) then) =
      __$NodeCopyWithImpl<$Res>;
  @override
  $Res call({String name, Node parent});
}

class __$NodeCopyWithImpl<$Res> extends _$NodeCopyWithImpl<$Res>
    implements _$NodeCopyWith<$Res> {
  __$NodeCopyWithImpl(_Node _value, $Res Function(_Node) _then)
      : super(_value, (v) => _then(v as _Node));

  @override
  _Node get _value => super._value as _Node;

  @override
  $Res call({
    Object name = freezed,
    Object parent = freezed,
  }) {
    return _then(_Node(
      name: name == freezed ? _value.name : name as String,
      parent: parent == freezed ? _value.parent : parent as Node,
    ));
  }
}

class _$_Node implements _Node {
  _$_Node({this.name, this.parent});

  @override
  final String name;
  @override
  final Node parent;

  @override
  String toString() {
    return 'Node(name: $name, parent: $parent)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _Node &&
            (identical(other.name, name) ||
                const DeepCollectionEquality().equals(other.name, name)) &&
            (identical(other.parent, parent) ||
                const DeepCollectionEquality().equals(other.parent, parent)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      const DeepCollectionEquality().hash(name) ^
      const DeepCollectionEquality().hash(parent);

  @override
  _$NodeCopyWith<_Node> get copyWith =>
      __$NodeCopyWithImpl<_Node>(this, _$identity);
}

abstract class _Node implements Node {
  factory _Node({String name, Node parent}) = _$_Node;

  @override
  String get name;
  @override
  Node get parent;
  @override
  _$NodeCopyWith<_Node> get copyWith;
}
