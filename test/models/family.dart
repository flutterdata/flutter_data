import 'package:flutter_data/flutter_data.dart';
import 'package:flutter_data/annotations.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

import 'house.dart';
import 'person.dart';
import 'pet.dart';

part 'family.g.dart';

@JsonSerializable(explicitToJson: true)
@DataRepository([])
class Family with DataSupport<Family> {
  @override
  final String id;
  final String surname;
  final HasMany<Person> persons;
  final BelongsTo<House> cottage;
  final BelongsTo<House> residence;
  final HasMany<Dog> dogs;

  Family({
    this.id,
    @required this.surname,
    this.persons,
    this.cottage,
    this.residence,
    this.dogs,
  });

  // no fromJson or toJson on purpose (testing codegen)

  @override
  bool operator ==(o) => o is Family && surname == o.surname;

  @override
  int get hashCode => runtimeType.hashCode ^ surname.hashCode;
}
