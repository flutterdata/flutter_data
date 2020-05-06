import 'dart:async';
import 'dart:math';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:meta/meta.dart';
import 'package:flutter_data/flutter_data.dart';
import 'package:flutter_data/annotations.dart';
import 'family.dart';

part 'person.g.dart';

@DataRepository([PersonPollAdapter])
class Person with DataSupportMixin<Person> {
  @override
  final String id;
  final String name;
  final int age;
  BelongsTo<Family> family;

  Person({
    this.id,
    @required this.name,
    @required this.age,
    this.family,
  });

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
            id: withId ? Random().nextInt(84).toString() : null,
            name: 'zzz-${Random().nextInt(9999)}',
            age: Random().nextInt(88))
        .init(repository);
  }
}

// note: keep PersonPollAdapter without type arguments
// as part of testing this feature
mixin PersonPollAdapter on Repository<Person> {
  void generatePeople() {
    Timer.periodic(Duration(seconds: 1), (_) {
      Person.generateRandom(this);
    });
  }
}
