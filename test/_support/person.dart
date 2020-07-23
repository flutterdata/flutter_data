import 'dart:async';
import 'dart:math';

import 'package:meta/meta.dart';
import 'package:flutter_data/flutter_data.dart';
import 'family.dart';

part 'person.g.dart';

@DataRepository(
    [PersonLoginAdapter, GenericDoesNothingAdapter, YetAnotherLoginAdapter])
class Person with DataModel<Person> {
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
  Future<String> login(String email, String password) async {
    return await withRequest<String>(
      '/token',
      body: '',
      headers: (await headers)
        ..addAll({
          'response':
              '{ "token": "$password" ${email == null ? '&*@%%*#@!' : ''} }'
        }),
      onSuccess: (data) => data['token'] as String,
      onError: (e) => throw UnsupportedError('custom error: $e'),
    );
  }
}

mixin GenericDoesNothingAdapter<T extends DataModel<T>> on RemoteAdapter<T> {
  Future<T> doNothing(T model, int n) async {
    return model;
  }
}

mixin YetAnotherLoginAdapter on PersonLoginAdapter {
  @override
  Future<String> login(String email, String password) async {
    return super.login(email, password);
  }
}
