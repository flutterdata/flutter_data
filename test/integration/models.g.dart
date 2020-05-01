// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// DataGenerator
// **************************************************************************

// ignore_for_file: unused_local_variable
// ignore_for_file: always_declare_return_types
class _$ModelRepository extends Repository<Model> {
  _$ModelRepository(LocalAdapter<Model> adapter, {bool remote, bool verbose})
      : super(adapter, remote: remote, verbose: verbose);

  @override
  get relationshipMetadata => {
        'HasMany': {},
        'BelongsTo': {'company': 'companies'},
        'repository#companies': manager.locator<Repository<Company>>()
      };
}

class $ModelRepository extends _$ModelRepository {
  $ModelRepository(LocalAdapter<Model> adapter, {bool remote, bool verbose})
      : super(adapter, remote: remote, verbose: verbose);
}

// ignore: must_be_immutable, unused_local_variable
class $ModelLocalAdapter extends LocalAdapter<Model> {
  $ModelLocalAdapter(DataManager manager, {List<int> encryptionKey, box})
      : super(manager, encryptionKey: encryptionKey, box: box);

  @override
  deserialize(map) {
    map['company'] = {
      '_': [map['company'], manager]
    };
    return Model.fromJson(map);
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

// ignore_for_file: unused_local_variable
// ignore_for_file: always_declare_return_types
class _$CityRepository extends Repository<City> {
  _$CityRepository(LocalAdapter<City> adapter, {bool remote, bool verbose})
      : super(adapter, remote: remote, verbose: verbose);

  @override
  get relationshipMetadata => {'HasMany': {}, 'BelongsTo': {}};
}

class $CityRepository extends _$CityRepository {
  $CityRepository(LocalAdapter<City> adapter, {bool remote, bool verbose})
      : super(adapter, remote: remote, verbose: verbose);
}

// ignore: must_be_immutable, unused_local_variable
class $CityLocalAdapter extends LocalAdapter<City> {
  $CityLocalAdapter(DataManager manager, {List<int> encryptionKey, box})
      : super(manager, encryptionKey: encryptionKey, box: box);

  @override
  deserialize(map) {
    return City.fromJson(map);
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

// ignore_for_file: unused_local_variable
// ignore_for_file: always_declare_return_types
class _$CompanyRepository extends Repository<Company> {
  _$CompanyRepository(LocalAdapter<Company> adapter,
      {bool remote, bool verbose})
      : super(adapter, remote: remote, verbose: verbose);

  @override
  get relationshipMetadata => {
        'HasMany': {'models': 'models'},
        'BelongsTo': {},
        'repository#models': manager.locator<Repository<Model>>()
      };
}

class $CompanyRepository extends _$CompanyRepository
    with JSONAPIAdapter<Company>, TestMixin<Company> {
  $CompanyRepository(LocalAdapter<Company> adapter, {bool remote, bool verbose})
      : super(adapter, remote: remote, verbose: verbose);
}

// ignore: must_be_immutable, unused_local_variable
class $CompanyLocalAdapter extends LocalAdapter<Company> {
  $CompanyLocalAdapter(DataManager manager, {List<int> encryptionKey, box})
      : super(manager, encryptionKey: encryptionKey, box: box);

  @override
  deserialize(map) {
    map['models'] = {
      '_': [map['models'], manager]
    };
    return Company.fromJson(map);
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
