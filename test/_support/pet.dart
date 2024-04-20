import 'package:equatable/equatable.dart';
import 'package:flutter_data/flutter_data.dart';
import 'package:json_annotation/json_annotation.dart';

part 'pet.g.dart';

abstract class Pet<T extends Pet<T>> extends DataModel<T> {
  @override
  final String? id;
  Pet(this.id);
}

@DataAdapter([]) // , remote: false
@JsonSerializable()
class Dog extends Pet<Dog> with EquatableMixin {
  final String name;
  // NOTE: do not add BelongsTo<Familia>, we are testing that
  // one-way relationship (Familia: HasMany<Dog>)
  Dog({String? id, required this.name}) : super(id);
  factory Dog.fromJson(Map<String, dynamic> json) => _$DogFromJson(json);
  Map<String, dynamic> toJson() => _$DogToJson(this);

  @override
  List<Object?> get props => [id, name];

  @override
  String toString() {
    return '{ id: $id, name: $name }';
  }
}

@DataAdapter([])
@JsonSerializable()
class Cat extends Pet<Cat> {
  final bool meow;

  Cat({String? id, required this.meow}) : super(id);
  factory Cat.fromJson(Map<String, dynamic> json) => _$CatFromJson(json);
  Map<String, dynamic> toJson() => _$CatToJson(this);
}
