import 'package:flutter_data/annotations.dart';
import 'package:flutter_data/flutter_data.dart';
import 'package:flutter_data/adapters/json_api_adapter.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'models.freezed.dart';
part 'models.g.dart';

@freezed
@DataRepository([])
abstract class Model with DataSupportMixin<Model>, _$Model {
  Model._();
  factory Model({
    String id,
    String name,
    BelongsTo<Company> company,
  }) = _Model;

  factory Model.fromJson(Map<String, dynamic> json) => _$ModelFromJson(json);
}

@freezed
@DataRepository([])
abstract class City with DataSupportMixin<City>, _$City {
  City._();
  factory City({
    String id,
    String name,
  }) = _City;

  factory City.fromJson(Map<String, dynamic> json) => _$CityFromJson(json);
}

@freezed
@DataRepository([JSONAPIAdapter, TestMixin])
abstract class Company with DataSupportMixin<Company>, _$Company {
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

mixin TestMixin<T extends DataSupportMixin<T>> on RemoteAdapter<T> {
  @override
  String get baseUrl => 'http://127.0.0.1:17083/';

  @override
  Map<String, dynamic> get params => {
        'page': {'limit': 10}
      };

  @override
  Map<String, String> get headers => {'x-client-id': '2473272'};
}

// mixin ImpatientModel on Repository<Model> {
//   @override
//   Duration get requestTimeout => Duration(microseconds: 1);
// }

class ModelTestRepository = $ModelRepository with TestMixin, JSONAPIAdapter;
class CityTestRepository = $CityRepository with TestMixin, JSONAPIAdapter;

// class ImpatientModelTestRepository = $ModelRepository
//     with TestMixin, JSONAPIAdapter, ImpatientModel;
