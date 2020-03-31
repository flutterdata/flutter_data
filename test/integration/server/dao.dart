import 'package:json_api/document.dart';

import 'collection.dart';
import 'job_queue.dart';
import 'model.dart';

abstract class DAO<T> {
  final _collection = <String, T>{};

  int get length => _collection.length;

  Resource toResource(T t);

  T create(Resource resource);

  T fetchById(String id) => _collection[id];

  Resource fetchByIdAsResource(String id) =>
      _collection.containsKey(id) ? toResource(_collection[id]) : null;

  void insert(T t); // => collection[t.id] = t;

  Collection<T> fetchCollection(int limit, int offset) => Collection(
      _collection.values.skip(offset).take(limit).toList(), _collection.length);

  /// Returns the number of depending objects the entity had
  int deleteById(String id) {
    _collection.remove(id);
    return 0;
  }

  Resource update(String id, Resource resource) {
    throw UnimplementedError();
  }

  void replaceToOne(String id, String relationship, Identifier identifier) {
    throw UnimplementedError();
  }

  void replaceToMany(
      String id, String relationship, Iterable<Identifier> identifiers) {
    throw UnimplementedError();
  }

  List<Identifier> addToMany(
      String id, String relationship, Iterable<Identifier> identifiers) {
    throw UnimplementedError();
  }
}

class ModelDAO extends DAO<Model> {
  @override
  Resource toResource(Model _) =>
      Resource('models', _.id, attributes: {'name': _.name});

  @override
  void insert(Model model) => _collection[model.id] = model;

  @override
  Model create(Resource r) {
    return Model(r.id)..name = r.attributes['name'] as String;
  }

  @override
  Resource update(String id, Resource resource) {
    _collection[id].name = resource.attributes['name'] as String;
    return null;
  }
}

class CityDAO extends DAO<City> {
  @override
  Resource toResource(City _) =>
      Resource('cities', _.id, attributes: {'name': _.name});

  @override
  void insert(City city) => _collection[city.id] = city;

  @override
  City create(Resource r) {
    return City(r.id)..name = r.attributes['name'] as String;
  }
}

class CompanyDAO extends DAO<Company> {
  @override
  Resource toResource(Company company) =>
      Resource('companies', company.id, attributes: {
        'name': company.name,
        'nasdaq': company.nasdaq,
        'updatedAt': company.updatedAt.toIso8601String()
      }, toOne: {
        'hq': company.headquarters == null
            ? null
            : Identifier('cities', company.headquarters)
      }, toMany: {
        'models': company.models.map((_) => Identifier('models', _)).toList()
      });

  @override
  void insert(Company company) {
    company.updatedAt = DateTime.now();
    _collection[company.id] = company;
  }

  @override
  Company create(Resource r) {
    return Company(r.id)
      ..name = r.attributes['name'] as String
      ..updatedAt = DateTime.now();
  }

  @override
  int deleteById(String id) {
    final company = fetchById(id);
    var deps = company.headquarters == null ? 0 : 1;
    deps += company.models.length;
    _collection.remove(id);
    return deps;
  }

  @override
  Resource update(String id, Resource resource) {
    final company = _collection[id];
    if (resource.attributes.containsKey('name')) {
      company.name = resource.attributes['name'] as String;
    }
    if (resource.attributes.containsKey('nasdaq')) {
      company.nasdaq = resource.attributes['nasdaq'] as String;
    }
    if (resource.toOne.containsKey('hq')) {
      company.headquarters = resource.toOne['hq']?.id;
    }
    if (resource.toMany.containsKey('models')) {
      company.models.clear();
      company.models.addAll(resource.toMany['models'].map((_) => _.id));
    }
    company.updatedAt = DateTime.now();
    return toResource(company);
  }

  @override
  void replaceToOne(String id, String relationship, Identifier identifier) {
    final company = _collection[id];
    switch (relationship) {
      case 'hq':
        company.headquarters = identifier?.id;
    }
  }

  @override
  void replaceToMany(
      String id, String relationship, Iterable<Identifier> identifiers) {
    final company = _collection[id];
    switch (relationship) {
      case 'models':
        company.models.clear();
        company.models.addAll(identifiers.map((_) => _.id));
    }
  }

  @override
  List<Identifier> addToMany(
      String id, String relationship, Iterable<Identifier> identifiers) {
    final company = _collection[id];
    switch (relationship) {
      case 'models':
        company.models.addAll(identifiers.map((_) => _.id));
        return company.models.map((_) => Identifier('models', _)).toList();
    }
    throw ArgumentError();
  }
}

class JobDAO extends DAO<Job> {
  @override
  Job create(Resource resource) {
    throw UnsupportedError('Jobs are created internally');
  }

  @override
  void insert(Job job) => _collection[job.id] = job;

  @override
  Resource toResource(Job job) => Resource('jobs', job.id);
}
