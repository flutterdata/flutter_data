import 'dart:async';
import 'dart:math';

import 'package:http/testing.dart';
import 'package:meta/meta.dart';
import 'package:flutter_data/flutter_data.dart';
import 'package:http/http.dart' as http;
import 'family.dart';

part 'person.g.dart';

@DataRepository([PersonLoginAdapter])
class Person with DataSupport<Person> {
  @override
  final String id;
  final String name;
  final int age;
  final BelongsTo<Family> family;

  Person({
    this.id,
    @required this.name,
    @required this.age,
    BelongsTo<Family> family,
  }) : family = family ?? BelongsTo();

  // testing without jsonserializable
  // also, simulates a @JsonKey(name: '_id) on `id`
  factory Person.fromJson(Map<String, dynamic> json) => Person(
        id: json['_id'] as String,
        name: json['name'] as String,
        age: json['age'] as int,
        family: json['family'] == null
            ? null
            : BelongsTo.fromJson(json['family'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'age': age,
        'family': family.toJson(),
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

  //

  factory Person.generate(owner, {String withId}) {
    return Person(
            id: withId,
            name: 'Person Number ${withId ?? Random().nextInt(999999999)}',
            age: Random().nextInt(19))
        .init(owner);
  }
}

// NOTE: keep this adapter without type arguments
// as part of testing the type-parameter-less adapter feature
mixin PersonLoginAdapter on RemoteAdapter<Person> {
  @override
  String get baseUrl => '';

  Future<String> login(String email, String password) async {
    return await withRequest<String>(
      '/token',
      body: '',
      headers: await headers,
      onSuccess: (data) => data['token'] as String,
    );
  }
}

mixin TestLoginAdapter on PersonLoginAdapter {
  @override
  http.Client get httpClient {
    return MockClient((req) {
      return Future.value(http.Response('{ "token": "zzz1" }', 200));
    });
  }
}
