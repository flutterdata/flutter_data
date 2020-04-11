import 'package:flutter_data/annotations.dart';
import 'package:flutter_data/flutter_data.dart';
import 'package:flutter_data/src/adapter/remote/json_api_adapter.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'models.freezed.dart';
part 'models.g.dart';

@freezed
@DataRepository()
abstract class Model with _$Model, DataSupportMixin<Model> {
  Model._();
  factory Model({
    String id,
    String name,
    BelongsTo<Company> company,
  }) = _Model;

  factory Model.fromJson(Map<String, dynamic> json) => _$ModelFromJson(json);
}

@freezed
@DataRepository()
abstract class City with _$City, DataSupportMixin<City> {
  City._();
  factory City({
    String id,
    String name,
  }) = _City;

  factory City.fromJson(Map<String, dynamic> json) => _$CityFromJson(json);
}

@freezed
@DataRepository([JSONAPIAdapter, TestMixin])
abstract class Company with _$Company, DataSupportMixin<Company> {
  Company._();
  factory Company({
    String id,
    String name,
    String nasdaq,
    DateTime updatedAt,
    HasMany<Model> models,
  }) = _Company;

  factory Company.fromJson(Map<String, dynamic> json) =>
      _$CompanyFromJson(json);
}

//

mixin TestMixin<T extends DataSupportMixin<T>> on Repository<T> {
  @override
  get baseUrl => 'http://127.0.0.1:17083/';
}

class ModelTestRepository = $ModelRepository with TestMixin, JSONAPIAdapter;
class CityTestRepository = $CityRepository with TestMixin, JSONAPIAdapter;
