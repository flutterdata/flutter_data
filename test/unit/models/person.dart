import 'dart:async';
import 'dart:math';

import 'package:json_annotation/json_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:meta/meta.dart';
import 'package:flutter_data/flutter_data.dart';
import 'package:flutter_data/annotations.dart';
import 'family.dart';

part 'person.g.dart';

@JsonSerializable()
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

  factory Person.fromJson(Map<String, dynamic> json) => _$PersonFromJson(json);
  Map<String, dynamic> toJson() => _$PersonToJson(this);

  bool operator ==(o) => o is Person && name == o.name && age == o.age;
  int get hashCode => runtimeType.hashCode ^ name.hashCode ^ age.hashCode;

  @override
  String toString() {
    return toJson().toString();
  }
}

mixin PersonPollAdapter<T extends Person> on Repository<Person> {
  generatePeople() {
    Timer.periodic(Duration(seconds: 1), (_) async {
      Person(name: 'zzz-${Random().nextInt(9999)}', age: Random().nextInt(88))
          .init(this);
    });
  }
}
