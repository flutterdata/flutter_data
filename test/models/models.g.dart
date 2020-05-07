// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// DataGenerator
// **************************************************************************

// ignore_for_file: unused_local_variable
// ignore_for_file: always_declare_return_types
mixin _$ModelModelAdapter on Repository<Model> {
  @override
  get relationshipMetadata => {
        'HasMany': {},
        'BelongsTo': {'company': 'companies'}
      };

  @override
  Repository repositoryFor(String type) {
    return <String, Repository>{
      'companies': manager.locator<Repository<Company>>()
    }[type];
  }

  @override
  deserialize(map, {key, initialize = true}) {
    map['company'] = {
      '_': [map['company'], manager]
    };
    return Model.fromJson(map as Map<String, dynamic>);
  }

  @override
  serialize(model) {
    final map = model.toJson();
    map['company'] = model.company?.toJson();
    return map;
  }

  @override
  setOwnerInRelationships(owner, model) {
    model.company?.owner = owner;
  }

  @override
  void setInverseInModel(inverse, model) {
    if (inverse is DataId<Company>) {
      model.company?.inverse = inverse;
    }
  }
}

class $ModelRepository = Repository<Model>
    with _$ModelModelAdapter, RemoteAdapter<Model>, WatchAdapter<Model>;

// ignore_for_file: unused_local_variable
// ignore_for_file: always_declare_return_types
mixin _$CityModelAdapter on Repository<City> {
  @override
  get relationshipMetadata => {'HasMany': {}, 'BelongsTo': {}};

  @override
  Repository repositoryFor(String type) {
    return <String, Repository>{}[type];
  }

  @override
  deserialize(map, {key, initialize = true}) {
    return City.fromJson(map as Map<String, dynamic>);
  }

  @override
  serialize(model) {
    final map = model.toJson();

    return map;
  }

  @override
  setOwnerInRelationships(owner, model) {}

  @override
  void setInverseInModel(inverse, model) {}
}

class $CityRepository = Repository<City>
    with _$CityModelAdapter, RemoteAdapter<City>, WatchAdapter<City>;

// ignore_for_file: unused_local_variable
// ignore_for_file: always_declare_return_types
mixin _$CompanyModelAdapter on Repository<Company> {
  @override
  get relationshipMetadata => {
        'HasMany': {'models': 'models'},
        'BelongsTo': {}
      };

  @override
  Repository repositoryFor(String type) {
    return <String, Repository>{
      'models': manager.locator<Repository<Model>>()
    }[type];
  }

  @override
  deserialize(map, {key, initialize = true}) {
    map['models'] = {
      '_': [map['models'], manager]
    };
    return Company.fromJson(map as Map<String, dynamic>);
  }

  @override
  serialize(model) {
    final map = model.toJson();
    map['models'] = model.models?.toJson();
    return map;
  }

  @override
  setOwnerInRelationships(owner, model) {
    model.models?.owner = owner;
  }

  @override
  void setInverseInModel(inverse, model) {
    if (inverse is DataId<Model>) {
      model.models?.inverse = inverse;
    }
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
