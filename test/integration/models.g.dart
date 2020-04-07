// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// DataGenerator
// **************************************************************************

// ignore_for_file: unused_local_variable
class _$ModelRepository extends Repository<Model> {
  _$ModelRepository(LocalAdapter<Model> adapter) : super(adapter);

  @override
  get relationshipMetadata => {
        'HasMany': {},
        'BelongsTo': {'company': 'companies'},
        'repository#companies': manager.locator<Repository<Company>>()
      };

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

class $ModelRepository extends _$ModelRepository {
  $ModelRepository(LocalAdapter<Model> adapter) : super(adapter);
}

// ignore: must_be_immutable, unused_local_variable
class $ModelLocalAdapter extends LocalAdapter<Model> {
  $ModelLocalAdapter(box, DataManager manager) : super(box, manager);

  @override
  deserialize(map, {key}) {
    map['company'] = {
      '_': [map['company'], manager]
    };

    manager.dataId<Model>(map.id, key: key);
    return Model.fromJson(map);
  }

  @override
  serialize(model) {
    final map = model.toJson();
    map['company'] = model.company?.toJson();
    return map;
  }
}

// ignore_for_file: unused_local_variable
class _$CityRepository extends Repository<City> {
  _$CityRepository(LocalAdapter<City> adapter) : super(adapter);

  @override
  get relationshipMetadata => {'HasMany': {}, 'BelongsTo': {}};

  @override
  setOwnerInRelationships(owner, model) {}

  @override
  void setInverseInModel(inverse, model) {}
}

class $CityRepository extends _$CityRepository {
  $CityRepository(LocalAdapter<City> adapter) : super(adapter);
}

// ignore: must_be_immutable, unused_local_variable
class $CityLocalAdapter extends LocalAdapter<City> {
  $CityLocalAdapter(box, DataManager manager) : super(box, manager);

  @override
  deserialize(map, {key}) {
    manager.dataId<City>(map.id, key: key);
    return City.fromJson(map);
  }

  @override
  serialize(model) {
    final map = model.toJson();

    return map;
  }
}

// ignore_for_file: unused_local_variable
class _$CompanyRepository extends Repository<Company> {
  _$CompanyRepository(LocalAdapter<Company> adapter) : super(adapter);

  @override
  get relationshipMetadata => {
        'HasMany': {'models': 'models'},
        'BelongsTo': {},
        'repository#models': manager.locator<Repository<Model>>()
      };

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

class $CompanyRepository extends _$CompanyRepository
    with JSONAPIAdapter<Company>, TestMixin<Company> {
  $CompanyRepository(LocalAdapter<Company> adapter) : super(adapter);
}

// ignore: must_be_immutable, unused_local_variable
class $CompanyLocalAdapter extends LocalAdapter<Company> {
  $CompanyLocalAdapter(box, DataManager manager) : super(box, manager);

  @override
  deserialize(map, {key}) {
    map['models'] = {
      '_': [map['models'], manager]
    };

    manager.dataId<Company>(map.id, key: key);
    return Company.fromJson(map);
  }

  @override
  serialize(model) {
    final map = model.toJson();
    map['models'] = model.models?.toJson();
    return map;
  }
}

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
