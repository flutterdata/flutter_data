// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// DataGenerator
// **************************************************************************

// ignore_for_file: unused_local_variable, always_declare_return_types, non_constant_identifier_names
mixin _$ModelModelAdapter on Repository<Model> {
  @override
  Map<String, Map<String, Object>> relationshipsFor([Model model]) => {
        'company': {
          'type': 'companies',
          'kind': 'BelongsTo',
          'instance': model?.company
        }
      };

  @override
  Map<String, Repository> get relatedRepositories =>
      {'companies': manager.locator<Repository<Company>>()};

  @override
  localDeserialize(map) {
    for (var key in relationshipsFor().keys) {
      map[key] = {
        '_': [map[key], !map.containsKey(key), manager]
      };
    }
    return _$ModelFromJson(map);
  }

  @override
  localSerialize(model) {
    final map = _$ModelToJson(model);
    for (var e in relationshipsFor(model).entries) {
      map[e.key] = (e.value['instance'] as Relationship)?.toJson();
    }
    return map;
  }
}

class $ModelRepository = Repository<Model>
    with _$ModelModelAdapter, RemoteAdapter<Model>, WatchAdapter<Model>;

// ignore_for_file: unused_local_variable, always_declare_return_types, non_constant_identifier_names
mixin _$CityModelAdapter on Repository<City> {
  @override
  Map<String, Map<String, Object>> relationshipsFor([City model]) => {};

  @override
  Map<String, Repository> get relatedRepositories => {};

  @override
  localDeserialize(map) {
    for (var key in relationshipsFor().keys) {
      map[key] = {
        '_': [map[key], !map.containsKey(key), manager]
      };
    }
    return City.fromJson(map);
  }

  @override
  localSerialize(model) {
    final map = model.toJson();
    for (var e in relationshipsFor(model).entries) {
      map[e.key] = (e.value['instance'] as Relationship)?.toJson();
    }
    return map;
  }
}

class $CityRepository = Repository<City>
    with _$CityModelAdapter, RemoteAdapter<City>, WatchAdapter<City>;

// ignore_for_file: unused_local_variable, always_declare_return_types, non_constant_identifier_names
mixin _$CompanyModelAdapter on Repository<Company> {
  @override
  Map<String, Map<String, Object>> relationshipsFor([Company model]) => {
        'models': {
          'type': 'models',
          'kind': 'HasMany',
          'instance': model?.models
        }
      };

  @override
  Map<String, Repository> get relatedRepositories =>
      {'models': manager.locator<Repository<Model>>()};

  @override
  localDeserialize(map) {
    for (var key in relationshipsFor().keys) {
      map[key] = {
        '_': [map[key], !map.containsKey(key), manager]
      };
    }
    return Company.fromJson(map);
  }

  @override
  localSerialize(model) {
    final map = model.toJson();
    for (var e in relationshipsFor(model).entries) {
      map[e.key] = (e.value['instance'] as Relationship)?.toJson();
    }
    return map;
  }
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

Model _$ModelFromJson(Map<String, dynamic> json) {
  return Model(
    id: json['id'] as String,
    name: json['name'] as String,
    company: json['company'] == null
        ? null
        : BelongsTo.fromJson(json['company'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$ModelToJson(Model instance) => <String, dynamic>{
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
