import 'package:flutter_data/flutter_data.dart';
import 'package:flutter_data/annotations.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

import 'house.dart';
import 'person.dart';
import 'pet.dart';

part 'family.g.dart';

@JsonSerializable(explicitToJson: true)
@DataRepository()
class Family with DataSupportMixin<Family> {
  @override
  final String id;
  final String surname;
  final BelongsTo<House> house; // immutable w/ default
  HasMany<Person> persons; // mutable and w/o default
  HasMany<Dog> dogs;

  Family({
    this.id,
    @required this.surname,
    BelongsTo<House> house,
    this.persons,
    this.dogs,
  }) : house = house ?? BelongsTo<House>();

  factory Family.fromJson(Map<String, dynamic> json) => _$FamilyFromJson(json);
  Map<String, dynamic> toJson() => _$FamilyToJson(this);

  bool operator ==(o) => o is Family && surname == o.surname;
  int get hashCode => runtimeType.hashCode ^ surname.hashCode;
}
