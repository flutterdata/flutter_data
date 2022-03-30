import 'package:flutter_data/flutter_data.dart';
import 'package:json_annotation/json_annotation.dart';

import 'house.dart';
import 'person.dart';
import 'pet.dart';

part 'family.g.dart';

@JsonSerializable(explicitToJson: true, includeIfNull: false)
@DataRepository([])
class Family with DataModel<Family> {
  @override
  final String? id;
  final String surname;
  late final HasMany<Person> persons;
  final BelongsTo<House>? cottage;
  final BelongsTo<House>? residence;
  final HasMany<Dog>? dogs;

  Family({
    this.id,
    required this.surname,
    HasMany<Person>? persons,
    this.cottage,
    this.residence,
    this.dogs,
  }) : persons = persons ?? HasMany();

  // no fromJson or toJson on purpose (testing codegen)

  @override
  bool operator ==(other) =>
      other is Family && id == other.id && surname == other.surname;

  @override
  int get hashCode => runtimeType.hashCode ^ id.hashCode ^ surname.hashCode;

  @override
  String toString() {
    return '{ id: $id, surname: $surname }';
  }
}
