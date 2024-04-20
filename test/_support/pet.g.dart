// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pet.dart';

// **************************************************************************
// RepositoryGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, duplicate_ignore

mixin _$DogAdapter on Adapter<Dog> {
  static final Map<String, RelationshipMeta> _kDogRelationshipMetas = {};

  @override
  Map<String, RelationshipMeta> get relationshipMetas => _kDogRelationshipMetas;

  @override
  Dog deserialize(map, {String? key}) {
    map = transformDeserialize(map);
    return internalWrapStopInit(() => Dog.fromJson(map), key: key);
  }

  @override
  Map<String, dynamic> serialize(model, {bool withRelationships = true}) {
    final map = model.toJson();
    return transformSerialize(map, withRelationships: withRelationships);
  }
}

final _dogsFinders = <String, dynamic>{};

class $DogAdapter = Adapter<Dog> with _$DogAdapter, NothingMixin;

final dogsAdapterProvider = Provider<Adapter<Dog>>(
    (ref) => $DogAdapter(ref, InternalHolder(_dogsFinders)));

extension DogAdapterX on Adapter<Dog> {}

extension DogRelationshipGraphNodeX on RelationshipGraphNode<Dog> {}

// ignore_for_file: non_constant_identifier_names, duplicate_ignore

mixin _$CatAdapter on Adapter<Cat> {
  static final Map<String, RelationshipMeta> _kCatRelationshipMetas = {};

  @override
  Map<String, RelationshipMeta> get relationshipMetas => _kCatRelationshipMetas;

  @override
  Cat deserialize(map, {String? key}) {
    map = transformDeserialize(map);
    return internalWrapStopInit(() => Cat.fromJson(map), key: key);
  }

  @override
  Map<String, dynamic> serialize(model, {bool withRelationships = true}) {
    final map = model.toJson();
    return transformSerialize(map, withRelationships: withRelationships);
  }
}

final _catsFinders = <String, dynamic>{};

class $CatAdapter = Adapter<Cat> with _$CatAdapter, NothingMixin;

final catsAdapterProvider = Provider<Adapter<Cat>>(
    (ref) => $CatAdapter(ref, InternalHolder(_catsFinders)));

extension CatAdapterX on Adapter<Cat> {}

extension CatRelationshipGraphNodeX on RelationshipGraphNode<Cat> {}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Dog _$DogFromJson(Map<String, dynamic> json) => Dog(
      id: json['id'] as String?,
      name: json['name'] as String,
    );

Map<String, dynamic> _$DogToJson(Dog instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
    };

Cat _$CatFromJson(Map<String, dynamic> json) => Cat(
      id: json['id'] as String?,
      meow: json['meow'] as bool,
    );

Map<String, dynamic> _$CatToJson(Cat instance) => <String, dynamic>{
      'id': instance.id,
      'meow': instance.meow,
    };
