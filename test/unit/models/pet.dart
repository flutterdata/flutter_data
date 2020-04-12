import 'package:flutter_data/annotations.dart';
import 'package:flutter_data/flutter_data.dart';
import 'package:json_annotation/json_annotation.dart';

part 'pet.g.dart';

abstract class Pet<T extends Pet<T>> extends DataSupportMixin<T> {
  final String id;
  Pet(this.id);
}

@DataRepository()
@JsonSerializable()
class Dog extends Pet<Dog> {
  final String name;

  Dog({String id, this.name}) : super(id);
  factory Dog.fromJson(Map<String, dynamic> json) => _$DogFromJson(json);
  Map<String, dynamic> toJson() => _$DogToJson(this);
}

@DataRepository()
@JsonSerializable()
class Cat extends Pet<Cat> {
  final bool meow;

  Cat({String id, this.meow}) : super(id);
  factory Cat.fromJson(Map<String, dynamic> json) => _$CatFromJson(json);
  Map<String, dynamic> toJson() => _$CatToJson(this);
}
