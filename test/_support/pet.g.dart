// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pet.dart';

// **************************************************************************
// RepositoryGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, duplicate_ignore

mixin $DogLocalAdapter on LocalAdapter<Dog> {
  static final Map<String, RelationshipMeta> _kDogRelationshipMetas = {};

  @override
  Map<String, RelationshipMeta> get relationshipMetas => _kDogRelationshipMetas;

  @override
  Dog deserialize(map) {
    map = transformDeserialize(map);
    return Dog.fromJson(map);
  }

  @override
  Map<String, dynamic> serialize(model, {bool withRelationships = true}) {
    final map = model.toJson();
    return transformSerialize(map, withRelationships: withRelationships);
  }
}

final _dogsFinders = <String, dynamic>{};

// ignore: must_be_immutable
class $DogHiveLocalAdapter = HiveLocalAdapter<Dog> with $DogLocalAdapter;

class $DogRemoteAdapter = RemoteAdapter<Dog> with NothingMixin;

final internalDogsRemoteAdapterProvider = Provider<RemoteAdapter<Dog>>((ref) =>
    $DogRemoteAdapter(
        $DogHiveLocalAdapter(ref.read), InternalHolder(_dogsFinders)));

final dogsRepositoryProvider =
    Provider<Repository<Dog>>((ref) => Repository<Dog>(ref.read));

extension DogDataRepositoryX on Repository<Dog> {}

extension DogRelationshipGraphNodeX on RelationshipGraphNode<Dog> {}

// ignore_for_file: non_constant_identifier_names, duplicate_ignore

mixin $CatLocalAdapter on LocalAdapter<Cat> {
  static final Map<String, RelationshipMeta> _kCatRelationshipMetas = {};

  @override
  Map<String, RelationshipMeta> get relationshipMetas => _kCatRelationshipMetas;

  @override
  Cat deserialize(map) {
    map = transformDeserialize(map);
    return Cat.fromJson(map);
  }

  @override
  Map<String, dynamic> serialize(model, {bool withRelationships = true}) {
    final map = model.toJson();
    return transformSerialize(map, withRelationships: withRelationships);
  }
}

final _catsFinders = <String, dynamic>{};

// ignore: must_be_immutable
class $CatHiveLocalAdapter = HiveLocalAdapter<Cat> with $CatLocalAdapter;

class $CatRemoteAdapter = RemoteAdapter<Cat> with NothingMixin;

final internalCatsRemoteAdapterProvider = Provider<RemoteAdapter<Cat>>((ref) =>
    $CatRemoteAdapter(
        $CatHiveLocalAdapter(ref.read), InternalHolder(_catsFinders)));

final catsRepositoryProvider =
    Provider<Repository<Cat>>((ref) => Repository<Cat>(ref.read));

extension CatDataRepositoryX on Repository<Cat> {}

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
