import 'package:json_annotation/json_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:meta/meta.dart';
import 'package:flutter_data/flutter_data.dart';
import 'package:flutter_data/annotations.dart';
import 'family.dart';

part 'person.g.dart';

@JsonSerializable()
@DataRepository()
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
  }) : family = family ?? BelongsTo<Family>();

  factory Person.fromJson(Map<String, dynamic> json) => _$PersonFromJson(json);
  Map<String, dynamic> toJson() => _$PersonToJson(this);

  bool operator ==(o) => o is Person && name == o.name && age == o.age;
  int get hashCode => runtimeType.hashCode ^ name.hashCode ^ age.hashCode;
}
