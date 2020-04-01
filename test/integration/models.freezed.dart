// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named

part of 'models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;
Model _$ModelFromJson(Map<String, dynamic> json) {
  return _Model.fromJson(json);
}

class _$ModelTearOff {
  const _$ModelTearOff();

  _Model call({String id, String name, BelongsTo<Company> company}) {
    return _Model(
      id: id,
      name: name,
      company: company,
    );
  }
}

// ignore: unused_element
const $Model = _$ModelTearOff();

mixin _$Model {
  String get id;
  String get name;
  BelongsTo<Company> get company;

  Map<String, dynamic> toJson();
  $ModelCopyWith<Model> get copyWith;
}

abstract class $ModelCopyWith<$Res> {
  factory $ModelCopyWith(Model value, $Res Function(Model) then) =
      _$ModelCopyWithImpl<$Res>;
  $Res call({String id, String name, BelongsTo<Company> company});
}

class _$ModelCopyWithImpl<$Res> implements $ModelCopyWith<$Res> {
  _$ModelCopyWithImpl(this._value, this._then);

  final Model _value;
  // ignore: unused_field
  final $Res Function(Model) _then;

  @override
  $Res call({
    Object id = freezed,
    Object name = freezed,
    Object company = freezed,
  }) {
    return _then(_value.copyWith(
      id: id == freezed ? _value.id : id as String,
      name: name == freezed ? _value.name : name as String,
      company:
          company == freezed ? _value.company : company as BelongsTo<Company>,
    ));
  }
}

abstract class _$ModelCopyWith<$Res> implements $ModelCopyWith<$Res> {
  factory _$ModelCopyWith(_Model value, $Res Function(_Model) then) =
      __$ModelCopyWithImpl<$Res>;
  @override
  $Res call({String id, String name, BelongsTo<Company> company});
}

class __$ModelCopyWithImpl<$Res> extends _$ModelCopyWithImpl<$Res>
    implements _$ModelCopyWith<$Res> {
  __$ModelCopyWithImpl(_Model _value, $Res Function(_Model) _then)
      : super(_value, (v) => _then(v as _Model));

  @override
  _Model get _value => super._value as _Model;

  @override
  $Res call({
    Object id = freezed,
    Object name = freezed,
    Object company = freezed,
  }) {
    return _then(_Model(
      id: id == freezed ? _value.id : id as String,
      name: name == freezed ? _value.name : name as String,
      company:
          company == freezed ? _value.company : company as BelongsTo<Company>,
    ));
  }
}

@JsonSerializable()
class _$_Model extends _Model {
  _$_Model({this.id, this.name, this.company}) : super._();

  factory _$_Model.fromJson(Map<String, dynamic> json) =>
      _$_$_ModelFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final BelongsTo<Company> company;

  @override
  String toString() {
    return 'Model(id: $id, name: $name, company: $company)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _Model &&
            (identical(other.id, id) ||
                const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.name, name) ||
                const DeepCollectionEquality().equals(other.name, name)) &&
            (identical(other.company, company) ||
                const DeepCollectionEquality().equals(other.company, company)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(name) ^
      const DeepCollectionEquality().hash(company);

  @override
  _$ModelCopyWith<_Model> get copyWith =>
      __$ModelCopyWithImpl<_Model>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$_$_ModelToJson(this);
  }
}

abstract class _Model extends Model {
  _Model._() : super._();
  factory _Model({String id, String name, BelongsTo<Company> company}) =
      _$_Model;

  factory _Model.fromJson(Map<String, dynamic> json) = _$_Model.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  BelongsTo<Company> get company;
  @override
  _$ModelCopyWith<_Model> get copyWith;
}

City _$CityFromJson(Map<String, dynamic> json) {
  return _City.fromJson(json);
}

class _$CityTearOff {
  const _$CityTearOff();

  _City call({String id, String name}) {
    return _City(
      id: id,
      name: name,
    );
  }
}

// ignore: unused_element
const $City = _$CityTearOff();

mixin _$City {
  String get id;
  String get name;

  Map<String, dynamic> toJson();
  $CityCopyWith<City> get copyWith;
}

abstract class $CityCopyWith<$Res> {
  factory $CityCopyWith(City value, $Res Function(City) then) =
      _$CityCopyWithImpl<$Res>;
  $Res call({String id, String name});
}

class _$CityCopyWithImpl<$Res> implements $CityCopyWith<$Res> {
  _$CityCopyWithImpl(this._value, this._then);

  final City _value;
  // ignore: unused_field
  final $Res Function(City) _then;

  @override
  $Res call({
    Object id = freezed,
    Object name = freezed,
  }) {
    return _then(_value.copyWith(
      id: id == freezed ? _value.id : id as String,
      name: name == freezed ? _value.name : name as String,
    ));
  }
}

abstract class _$CityCopyWith<$Res> implements $CityCopyWith<$Res> {
  factory _$CityCopyWith(_City value, $Res Function(_City) then) =
      __$CityCopyWithImpl<$Res>;
  @override
  $Res call({String id, String name});
}

class __$CityCopyWithImpl<$Res> extends _$CityCopyWithImpl<$Res>
    implements _$CityCopyWith<$Res> {
  __$CityCopyWithImpl(_City _value, $Res Function(_City) _then)
      : super(_value, (v) => _then(v as _City));

  @override
  _City get _value => super._value as _City;

  @override
  $Res call({
    Object id = freezed,
    Object name = freezed,
  }) {
    return _then(_City(
      id: id == freezed ? _value.id : id as String,
      name: name == freezed ? _value.name : name as String,
    ));
  }
}

@JsonSerializable()
class _$_City extends _City {
  _$_City({this.id, this.name}) : super._();

  factory _$_City.fromJson(Map<String, dynamic> json) =>
      _$_$_CityFromJson(json);

  @override
  final String id;
  @override
  final String name;

  @override
  String toString() {
    return 'City(id: $id, name: $name)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _City &&
            (identical(other.id, id) ||
                const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.name, name) ||
                const DeepCollectionEquality().equals(other.name, name)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(name);

  @override
  _$CityCopyWith<_City> get copyWith =>
      __$CityCopyWithImpl<_City>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$_$_CityToJson(this);
  }
}

abstract class _City extends City {
  _City._() : super._();
  factory _City({String id, String name}) = _$_City;

  factory _City.fromJson(Map<String, dynamic> json) = _$_City.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  _$CityCopyWith<_City> get copyWith;
}

Company _$CompanyFromJson(Map<String, dynamic> json) {
  return _Company.fromJson(json);
}

class _$CompanyTearOff {
  const _$CompanyTearOff();

  _Company call(
      {String id,
      String name,
      String nasdaq,
      DateTime updatedAt,
      HasMany<Model> models}) {
    return _Company(
      id: id,
      name: name,
      nasdaq: nasdaq,
      updatedAt: updatedAt,
      models: models,
    );
  }
}

// ignore: unused_element
const $Company = _$CompanyTearOff();

mixin _$Company {
  String get id;
  String get name;
  String get nasdaq;
  DateTime get updatedAt;
  HasMany<Model> get models;

  Map<String, dynamic> toJson();
  $CompanyCopyWith<Company> get copyWith;
}

abstract class $CompanyCopyWith<$Res> {
  factory $CompanyCopyWith(Company value, $Res Function(Company) then) =
      _$CompanyCopyWithImpl<$Res>;
  $Res call(
      {String id,
      String name,
      String nasdaq,
      DateTime updatedAt,
      HasMany<Model> models});
}

class _$CompanyCopyWithImpl<$Res> implements $CompanyCopyWith<$Res> {
  _$CompanyCopyWithImpl(this._value, this._then);

  final Company _value;
  // ignore: unused_field
  final $Res Function(Company) _then;

  @override
  $Res call({
    Object id = freezed,
    Object name = freezed,
    Object nasdaq = freezed,
    Object updatedAt = freezed,
    Object models = freezed,
  }) {
    return _then(_value.copyWith(
      id: id == freezed ? _value.id : id as String,
      name: name == freezed ? _value.name : name as String,
      nasdaq: nasdaq == freezed ? _value.nasdaq : nasdaq as String,
      updatedAt:
          updatedAt == freezed ? _value.updatedAt : updatedAt as DateTime,
      models: models == freezed ? _value.models : models as HasMany<Model>,
    ));
  }
}

abstract class _$CompanyCopyWith<$Res> implements $CompanyCopyWith<$Res> {
  factory _$CompanyCopyWith(_Company value, $Res Function(_Company) then) =
      __$CompanyCopyWithImpl<$Res>;
  @override
  $Res call(
      {String id,
      String name,
      String nasdaq,
      DateTime updatedAt,
      HasMany<Model> models});
}

class __$CompanyCopyWithImpl<$Res> extends _$CompanyCopyWithImpl<$Res>
    implements _$CompanyCopyWith<$Res> {
  __$CompanyCopyWithImpl(_Company _value, $Res Function(_Company) _then)
      : super(_value, (v) => _then(v as _Company));

  @override
  _Company get _value => super._value as _Company;

  @override
  $Res call({
    Object id = freezed,
    Object name = freezed,
    Object nasdaq = freezed,
    Object updatedAt = freezed,
    Object models = freezed,
  }) {
    return _then(_Company(
      id: id == freezed ? _value.id : id as String,
      name: name == freezed ? _value.name : name as String,
      nasdaq: nasdaq == freezed ? _value.nasdaq : nasdaq as String,
      updatedAt:
          updatedAt == freezed ? _value.updatedAt : updatedAt as DateTime,
      models: models == freezed ? _value.models : models as HasMany<Model>,
    ));
  }
}

@JsonSerializable()
class _$_Company extends _Company {
  _$_Company({this.id, this.name, this.nasdaq, this.updatedAt, this.models})
      : super._();

  factory _$_Company.fromJson(Map<String, dynamic> json) =>
      _$_$_CompanyFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String nasdaq;
  @override
  final DateTime updatedAt;
  @override
  final HasMany<Model> models;

  @override
  String toString() {
    return 'Company(id: $id, name: $name, nasdaq: $nasdaq, updatedAt: $updatedAt, models: $models)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _Company &&
            (identical(other.id, id) ||
                const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.name, name) ||
                const DeepCollectionEquality().equals(other.name, name)) &&
            (identical(other.nasdaq, nasdaq) ||
                const DeepCollectionEquality().equals(other.nasdaq, nasdaq)) &&
            (identical(other.updatedAt, updatedAt) ||
                const DeepCollectionEquality()
                    .equals(other.updatedAt, updatedAt)) &&
            (identical(other.models, models) ||
                const DeepCollectionEquality().equals(other.models, models)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(name) ^
      const DeepCollectionEquality().hash(nasdaq) ^
      const DeepCollectionEquality().hash(updatedAt) ^
      const DeepCollectionEquality().hash(models);

  @override
  _$CompanyCopyWith<_Company> get copyWith =>
      __$CompanyCopyWithImpl<_Company>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$_$_CompanyToJson(this);
  }
}

abstract class _Company extends Company {
  _Company._() : super._();
  factory _Company(
      {String id,
      String name,
      String nasdaq,
      DateTime updatedAt,
      HasMany<Model> models}) = _$_Company;

  factory _Company.fromJson(Map<String, dynamic> json) = _$_Company.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get nasdaq;
  @override
  DateTime get updatedAt;
  @override
  HasMany<Model> get models;
  @override
  _$CompanyCopyWith<_Company> get copyWith;
}
