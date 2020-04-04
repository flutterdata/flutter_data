// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// DataGenerator
// **************************************************************************

// ignore_for_file: unused_local_variable
class _$ModelRepository extends Repository<Model> {
  _$ModelRepository(LocalAdapter<Model> adapter) : super(adapter);

  @override
  Map<String, dynamic> get relationshipMetadata => {
        "HasMany": {},
        "BelongsTo": {"company": "companies"}
      };

  @override
  void setOwnerInRelationships(DataId<Model> owner, Model model) {
    model.company?.owner = owner;
  }

  @override
  void setOwnerInModel(DataId owner, Model model) {
    if (owner is DataId<Company>) {
      model.company?.owner = owner;
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
  deserialize(map, {key, included}) {
    map['company'] = {
      'BelongsTo': BelongsTo<Company>.fromKey(map['company'], manager,
          included: included)
    };

    manager.dataId<Model>(map.id, key: key);
    return Model.fromJson(map);
  }

  @override
  serialize(Model model) {
    return model.toJson();
  }
}

// ignore_for_file: unused_local_variable
class _$CityRepository extends Repository<City> {
  _$CityRepository(LocalAdapter<City> adapter) : super(adapter);

  @override
  Map<String, dynamic> get relationshipMetadata =>
      {"HasMany": {}, "BelongsTo": {}};

  @override
  void setOwnerInRelationships(DataId<City> owner, City model) {}

  @override
  void setOwnerInModel(DataId owner, City model) {}
}

class $CityRepository extends _$CityRepository {
  $CityRepository(LocalAdapter<City> adapter) : super(adapter);
}

// ignore: must_be_immutable, unused_local_variable
class $CityLocalAdapter extends LocalAdapter<City> {
  $CityLocalAdapter(box, DataManager manager) : super(box, manager);

  @override
  deserialize(map, {key, included}) {
    manager.dataId<City>(map.id, key: key);
    return City.fromJson(map);
  }

  @override
  serialize(City model) {
    return model.toJson();
  }
}

// ignore_for_file: unused_local_variable
class _$CompanyRepository extends Repository<Company> {
  _$CompanyRepository(LocalAdapter<Company> adapter) : super(adapter);

  @override
  Map<String, dynamic> get relationshipMetadata => {
        "HasMany": {"models": "models"},
        "BelongsTo": {}
      };

  @override
  void setOwnerInRelationships(DataId<Company> owner, Company model) {
    model.models?.owner = owner;
  }

  @override
  void setOwnerInModel(DataId owner, Company model) {
    if (owner is DataId<Model>) {
      model.models?.owner = owner;
    }
  }
}

class $CompanyRepository extends _$CompanyRepository with TestMixin<Company> {
  $CompanyRepository(LocalAdapter<Company> adapter) : super(adapter);
}

// ignore: must_be_immutable, unused_local_variable
class $CompanyLocalAdapter extends LocalAdapter<Company> {
  $CompanyLocalAdapter(box, DataManager manager) : super(box, manager);

  @override
  deserialize(map, {key, included}) {
    map['models'] = {
      'HasMany':
          HasMany<Model>.fromKeys(map['models'], manager, included: included)
    };

    manager.dataId<Company>(map.id, key: key);
    return Company.fromJson(map);
  }

  @override
  serialize(Company model) {
    return model.toJson();
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
