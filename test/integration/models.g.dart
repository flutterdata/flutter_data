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
  Model internalDeserialize(obj, {withKey, included}) {
    var map = <String, dynamic>{...?obj?.relationships};

    map['company'] = {
      'BelongsTo': BelongsTo<Company>.fromToOne(map['company'], manager,
          included: included)
    };

    var dataId = manager.dataId<Model>(obj.id, key: withKey);
    return Model.fromJson({
      ...{'id': dataId.id},
      ...obj.attributes,
      ...map,
    });
  }

  @override
  internalSerialize(Model model) {
    var relationships = {
      'company': model.company?.toOne,
    };

    final map = model.toJson();
    final dataId = manager.dataId<Model>(model.id);

    map.remove('id');
    map.remove('company');

    return DataResourceObject(
      dataId.type,
      dataId.id,
      attributes: map,
      relationships: relationships,
    );
  }

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
  Model internalLocalDeserialize(map) {
    map = fixMap(map);

    map['company'] = {
      'BelongsTo': BelongsTo<Company>.fromKey(map['company'], manager)
    };

    return Model.fromJson(map);
  }

  @override
  Map<String, dynamic> internalLocalSerialize(Model model) {
    var map = model.toJson();

    map['company'] = model.company?.key;
    return map;
  }
}

// ignore_for_file: unused_local_variable
class _$CityRepository extends Repository<City> {
  _$CityRepository(LocalAdapter<City> adapter) : super(adapter);

  @override
  Map<String, dynamic> get relationshipMetadata =>
      {"HasMany": {}, "BelongsTo": {}};

  @override
  City internalDeserialize(obj, {withKey, included}) {
    var map = <String, dynamic>{...?obj?.relationships};

    var dataId = manager.dataId<City>(obj.id, key: withKey);
    return City.fromJson({
      ...{'id': dataId.id},
      ...obj.attributes,
      ...map,
    });
  }

  @override
  internalSerialize(City model) {
    var relationships = {};

    final map = model.toJson();
    final dataId = manager.dataId<City>(model.id);

    map.remove('id');

    return DataResourceObject(
      dataId.type,
      dataId.id,
      attributes: map,
      relationships: null,
    );
  }

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
  City internalLocalDeserialize(map) {
    map = fixMap(map);

    return City.fromJson(map);
  }

  @override
  Map<String, dynamic> internalLocalSerialize(City model) {
    var map = model.toJson();

    return map;
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
  Company internalDeserialize(obj, {withKey, included}) {
    var map = <String, dynamic>{...?obj?.relationships};

    map['models'] = {
      'HasMany':
          HasMany<Model>.fromToMany(map['models'], manager, included: included)
    };

    var dataId = manager.dataId<Company>(obj.id, key: withKey);
    return Company.fromJson({
      ...{'id': dataId.id},
      ...obj.attributes,
      ...map,
    });
  }

  @override
  internalSerialize(Company model) {
    var relationships = {
      'models': model.models?.toMany,
    };

    final map = model.toJson();
    final dataId = manager.dataId<Company>(model.id);

    map.remove('id');
    map.remove('models');

    return DataResourceObject(
      dataId.type,
      dataId.id,
      attributes: map,
      relationships: relationships,
    );
  }

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
  Company internalLocalDeserialize(map) {
    map = fixMap(map);

    map['models'] = {
      'HasMany': HasMany<Model>.fromKeys(map['models'], manager)
    };

    return Company.fromJson(map);
  }

  @override
  Map<String, dynamic> internalLocalSerialize(Company model) {
    var map = model.toJson();
    map['models'] = model.models?.keys;

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
