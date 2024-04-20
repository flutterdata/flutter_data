import 'dart:async';
import 'dart:math';

import 'package:flutter_data/flutter_data.dart';
import 'familia.dart';

part 'person.g.dart';

@DataRepository(
    [PersonLoginAdapter, GenericDoesNothingAdapter, YetAnotherLoginAdapter],
    remote: false)
class Person extends DataModel<Person> {
  @override
  final String? id;
  final String name;
  final int? age;
  final BelongsTo<Familia> familia;

  Person({
    this.id,
    required this.name,
    this.age,
    BelongsTo<Familia>? familia,
  }) : familia = familia ?? BelongsTo();

  // testing without jsonserializable
  // also, simulates a @JsonKey(name: '_id) on `id`
  factory Person.fromJson(Map<String, dynamic> json) => Person(
        id: json['_id'] as String?,
        name: json['name'] as String,
        age: json['age'] as int?,
        familia: json['familia'] == null
            ? null
            : BelongsTo.fromJson(json['familia'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'age': age,
        'familia': familia.toJson(),
      };

  @override
  bool operator ==(other) =>
      other is Person &&
      id == other.id &&
      name == other.name &&
      age == other.age;

  @override
  int get hashCode =>
      runtimeType.hashCode ^ id.hashCode ^ name.hashCode ^ age.hashCode;

  @override
  String toString() {
    return 'Person $name ($age)';
  }

  //

  factory Person.generate({String? withId}) {
    return Person(
        id: withId,
        name: 'Number ${withId ?? Random().nextInt(999999999)}',
        age: Random().nextInt(19));
  }
}

// NOTE: keep this adapter without type arguments
// as part of testing the type-parameter-less adapter feature
mixin PersonLoginAdapter on Adapter<Person> {
  @override
  FutureOr<Map<String, String>> get defaultHeaders =>
      {'response': '{"message": "not the message you sent"}'};

  @override
  FutureOr<Map<String, dynamic>> get defaultParams => {'default': true};

  // if email is null it throws some garbage
  Future<String?> login(String? email, String? password) async {
    return await sendRequest(
      baseUrl.asUri / 'token' & await defaultParams & {'a': 1},
      onSuccess: (data, _) =>
          (data.body as Map<String, dynamic>?)?['token'] as String?,
      onError: (e, _) => throw UnsupportedError('custom error: $e'),
      omitDefaultParams: true,
    );
  }

  Future<String?> hello({bool useDefaultHeaders = false}) async {
    return await sendRequest(
      baseUrl.asUri / 'hello' & {'a': 1},
      headers: useDefaultHeaders ? null : {},
      onSuccess: (data, _) =>
          (data.body as Map<String, dynamic>?)?['message'].toString(),
    );
  }

  Future<String?> example() async {
    return await sendRequest(
      baseUrl.asUri / 'example',
      onSuccess: (data, _) => data.headers['X-Url'],
    );
  }

  Future<String?> url(Map<String, dynamic> params,
      {bool useDefaultParams = false}) async {
    return await sendRequest(
      baseUrl.asUri / 'url' & params,
      onSuccess: (data, _) =>
          (data.body as Map<String, dynamic>?)?['url'].toString(),
      omitDefaultParams: !useDefaultParams,
    );
  }
}

mixin GenericDoesNothingAdapter<T extends DataModel<T>> on Adapter<T> {
  Future<T?> doNothing(T? model, int n) async {
    return model;
  }
}

mixin YetAnotherLoginAdapter on PersonLoginAdapter {
  @override
  Future<String?> login(String? email, String? password) async {
    return super.login(email, password);
  }
}
