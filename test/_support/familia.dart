import 'package:flutter_data/flutter_data.dart';
import 'package:json_annotation/json_annotation.dart';

import 'house.dart';
import 'person.dart';
import 'pet.dart';

part 'familia.g.dart';

@JsonSerializable(explicitToJson: true, includeIfNull: false)
@DataRepository([], internalType: 'f', typeId: 5)
class Familia extends DataModel<Familia> {
  @override
  final String? id;
  final String surname;
  late final HasMany<Person> persons;
  @JsonKey(name: 'cottage_id')
  late final BelongsTo<House> cottage;
  final BelongsTo<House> residence;
  final HasMany<Dog>? dogs;

  Familia({
    this.id,
    required this.surname,
    HasMany<Person>? persons,
    BelongsTo<House>? cottage,
    BelongsTo<House>? residence,
    this.dogs,
  })  : persons = persons ?? HasMany(),
        cottage = cottage ?? BelongsTo(),
        residence = residence ?? BelongsTo();

  // no fromJson or toJson on purpose (testing codegen)

  @override
  bool operator ==(other) =>
      other is Familia && id == other.id && surname == other.surname;

  @override
  int get hashCode => runtimeType.hashCode ^ id.hashCode ^ surname.hashCode;

  @override
  String toString() {
    return '{ id: $id, surname: $surname, #persons: ${persons.length}, residence: $residence, cottage: $cottage }';
  }
}
