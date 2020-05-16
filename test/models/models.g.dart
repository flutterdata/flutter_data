// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// DataGenerator
// **************************************************************************

// ignore_for_file: unused_local_variable
// ignore_for_file: always_declare_return_types
mixin _$ModelModelAdapter on Repository<Model> {
  @override
  Map<String, Relationship> relationshipsFor(Model model) =>
      {'company': model?.company};

  @override
  Map<String, Repository> get relationshipRepositories =>
      {'companies': manager.locator<Repository<Company>>()};

  @override
  localDeserialize(map, {metadata}) {
    for (var key in relationshipsFor(null).keys) {
      map[key] = {
        '_': [map[key], !map.containsKey(key), manager]
      };
    }
    return Model.fromJson(map).._meta.addAll(metadata ?? const {});
  }

  @override
  localSerialize(model) {
    final map = model.toJson();
    for (var e in relationshipsFor(model).entries) {
      map[e.key] = e.value?.toJson();
    }
    return map;
  }
}

extension ModelFDX on Model {
  Map<String, dynamic> get _meta => flutterDataMetadata;
}

class $ModelRepository = Repository<Model>
    with _$ModelModelAdapter, RemoteAdapter<Model>, WatchAdapter<Model>;

// ignore_for_file: unused_local_variable
// ignore_for_file: always_declare_return_types
mixin _$CityModelAdapter on Repository<City> {
  @override
  Map<String, Relationship> relationshipsFor(City model) => {};

  @override
  Map<String, Repository> get relationshipRepositories => {};

  @override
  localDeserialize(map, {metadata}) {
    for (var key in relationshipsFor(null).keys) {
      map[key] = {
        '_': [map[key], !map.containsKey(key), manager]
      };
    }
    return City.fromJson(map).._meta.addAll(metadata ?? const {});
  }

  @override
  localSerialize(model) {
    final map = model.toJson();
    for (var e in relationshipsFor(model).entries) {
      map[e.key] = e.value?.toJson();
    }
    return map;
  }
}

extension CityFDX on City {
  Map<String, dynamic> get _meta => flutterDataMetadata;
}

class $CityRepository = Repository<City>
    with _$CityModelAdapter, RemoteAdapter<City>, WatchAdapter<City>;

// ignore_for_file: unused_local_variable
// ignore_for_file: always_declare_return_types
mixin _$CompanyModelAdapter on Repository<Company> {
  @override
  Map<String, Relationship> relationshipsFor(Company model) =>
      {'models': model?.models};

  @override
  Map<String, Repository> get relationshipRepositories =>
      {'models': manager.locator<Repository<Model>>()};

  @override
  localDeserialize(map, {metadata}) {
    for (var key in relationshipsFor(null).keys) {
      map[key] = {
        '_': [map[key], !map.containsKey(key), manager]
      };
    }
    return Company.fromJson(map).._meta.addAll(metadata ?? const {});
  }

  @override
  localSerialize(model) {
    final map = model.toJson();
    for (var e in relationshipsFor(model).entries) {
      map[e.key] = e.value?.toJson();
    }
    return map;
  }
}

extension CompanyFDX on Company {
  Map<String, dynamic> get _meta => flutterDataMetadata;
}

class $CompanyRepository = Repository<Company>
    with
        _$CompanyModelAdapter,
        RemoteAdapter<Company>,
        WatchAdapter<Company>,
        JSONAPIAdapter<Company>,
        TestMixin<Company>;

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$_Model _$_$_ModelFromJson(Map<String, dynamic> json) {
  return _$_Model(
    id: json['id'] as String,
    name: json['name'] as String,
    company: json['company'] == null
        ? null
        : BelongsTo.fromJson(json['company'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$_$_ModelToJson(_$_Model instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'company': instance.company,
    };

_$_City _$_$_CityFromJson(Map<String, dynamic> json) {
  return _$_City(
    id: json['id'] as String,
    name: json['name'] as String,
  );
}

Map<String, dynamic> _$_$_CityToJson(_$_City instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
    };

_$_Company _$_$_CompanyFromJson(Map<String, dynamic> json) {
  return _$_Company(
    id: json['id'] as String,
    name: json['name'] as String,
    nasdaq: json['nasdaq'] as String,
    updatedAt: json['updatedAt'] == null
        ? null
        : DateTime.parse(json['updatedAt'] as String),
    models: json['models'] == null
        ? null
        : HasMany.fromJson(json['models'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$_$_CompanyToJson(_$_Company instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'nasdaq': instance.nasdaq,
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'models': instance.models,
    };
