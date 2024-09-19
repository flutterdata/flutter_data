// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'node.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Node _$NodeFromJson(Map<String, dynamic> json) {
  return _Node.fromJson(json);
}

/// @nodoc
mixin _$Node {
  int? get id => throw _privateConstructorUsedError;
  String? get name => throw _privateConstructorUsedError;
  @DataRelationship(inverse: 'children')
  BelongsTo<Node>? get parent => throw _privateConstructorUsedError;
  @DataRelationship(inverse: 'parent')
  HasMany<Node>? get children => throw _privateConstructorUsedError;

  /// Serializes this Node to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Node
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NodeCopyWith<Node> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NodeCopyWith<$Res> {
  factory $NodeCopyWith(Node value, $Res Function(Node) then) =
      _$NodeCopyWithImpl<$Res, Node>;
  @useResult
  $Res call(
      {int? id,
      String? name,
      @DataRelationship(inverse: 'children') BelongsTo<Node>? parent,
      @DataRelationship(inverse: 'parent') HasMany<Node>? children});
}

/// @nodoc
class _$NodeCopyWithImpl<$Res, $Val extends Node>
    implements $NodeCopyWith<$Res> {
  _$NodeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Node
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? name = freezed,
    Object? parent = freezed,
    Object? children = freezed,
  }) {
    return _then(_value.copyWith(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      parent: freezed == parent
          ? _value.parent
          : parent // ignore: cast_nullable_to_non_nullable
              as BelongsTo<Node>?,
      children: freezed == children
          ? _value.children
          : children // ignore: cast_nullable_to_non_nullable
              as HasMany<Node>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$NodeImplCopyWith<$Res> implements $NodeCopyWith<$Res> {
  factory _$$NodeImplCopyWith(
          _$NodeImpl value, $Res Function(_$NodeImpl) then) =
      __$$NodeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int? id,
      String? name,
      @DataRelationship(inverse: 'children') BelongsTo<Node>? parent,
      @DataRelationship(inverse: 'parent') HasMany<Node>? children});
}

/// @nodoc
class __$$NodeImplCopyWithImpl<$Res>
    extends _$NodeCopyWithImpl<$Res, _$NodeImpl>
    implements _$$NodeImplCopyWith<$Res> {
  __$$NodeImplCopyWithImpl(_$NodeImpl _value, $Res Function(_$NodeImpl) _then)
      : super(_value, _then);

  /// Create a copy of Node
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? name = freezed,
    Object? parent = freezed,
    Object? children = freezed,
  }) {
    return _then(_$NodeImpl(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      parent: freezed == parent
          ? _value.parent
          : parent // ignore: cast_nullable_to_non_nullable
              as BelongsTo<Node>?,
      children: freezed == children
          ? _value.children
          : children // ignore: cast_nullable_to_non_nullable
              as HasMany<Node>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$NodeImpl extends _Node {
  _$NodeImpl(
      {this.id,
      this.name,
      @DataRelationship(inverse: 'children') this.parent,
      @DataRelationship(inverse: 'parent') this.children})
      : super._();

  factory _$NodeImpl.fromJson(Map<String, dynamic> json) =>
      _$$NodeImplFromJson(json);

  @override
  final int? id;
  @override
  final String? name;
  @override
  @DataRelationship(inverse: 'children')
  final BelongsTo<Node>? parent;
  @override
  @DataRelationship(inverse: 'parent')
  final HasMany<Node>? children;

  /// Create a copy of Node
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NodeImplCopyWith<_$NodeImpl> get copyWith =>
      __$$NodeImplCopyWithImpl<_$NodeImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$NodeImplToJson(
      this,
    );
  }
}

abstract class _Node extends Node {
  factory _Node(
          {final int? id,
          final String? name,
          @DataRelationship(inverse: 'children') final BelongsTo<Node>? parent,
          @DataRelationship(inverse: 'parent') final HasMany<Node>? children}) =
      _$NodeImpl;
  _Node._() : super._();

  factory _Node.fromJson(Map<String, dynamic> json) = _$NodeImpl.fromJson;

  @override
  int? get id;
  @override
  String? get name;
  @override
  @DataRelationship(inverse: 'children')
  BelongsTo<Node>? get parent;
  @override
  @DataRelationship(inverse: 'parent')
  HasMany<Node>? get children;

  /// Create a copy of Node
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NodeImplCopyWith<_$NodeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
