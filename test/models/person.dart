import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:http/testing.dart';
import 'package:meta/meta.dart';
import 'package:flutter_data/flutter_data.dart';
import 'package:flutter_data/annotations.dart';
import 'package:http/http.dart' as http;
import 'family.dart';

part 'person.g.dart';

@DataRepository([PersonLoginAdapter])
class Person with DataSupportMixin<Person> {
  @override
  final String id;
  final String name;
  final int age;
  @DataRelationship(inverse: 'persons')
  final BelongsTo<Family> family;

  Person({
    this.id,
    @required this.name,
    @required this.age,
    BelongsTo<Family> family,
  }) : family = family ?? BelongsTo();

  // testing without jsonserializable
  factory Person.fromJson(Map<String, dynamic> json) => Person(
        id: json['id'] as String,
        name: json['name'] as String,
        age: json['age'] as int,
        family: json['family'] == null
            ? null
            : BelongsTo.fromJson(json['family'] as Map<String, dynamic>),
      );
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'age': age,
        'family': family,
      };

  @override
  String toString() {
    return toJson().toString();
  }

  factory Person.generateRandom(Repository<Person> repository,
      {bool withId = false}) {
    return Person(
            id: withId ? Random().nextInt(19).toString() : null,
            name: 'zzz-${Random().nextInt(9999)}',
            age: Random().nextInt(19))
        .init(repository);
  }
}

// note: keep this adapter without type arguments
// as part of testing the type-parameter-less adapter feature
mixin PersonLoginAdapter on RemoteAdapter<Person> {
  @override
  String get baseUrl => '';

  Future<String> login(String email, String password) async {
    final response = await withHttpClient(
      (client) => client.post(
        '$baseUrl/token',
        body: '',
        headers: headers,
      ),
    );

    final map = json.decode(response.body);
    return map['token'] as String;
  }

  void generatePeople() {
    Timer.periodic(Duration(milliseconds: 60), (_) {
      Person.generateRandom(this);
    });
  }
}

mixin TestLoginAdapter on PersonLoginAdapter {
  @override
  Future<R> withHttpClient<R>(onRequest) {
    return onRequest(MockClient((req) {
      return Future(() => http.Response('{ "token": "zzz1" }', 200));
    }));
  }
}
