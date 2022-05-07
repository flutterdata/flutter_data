import 'package:flutter_data/flutter_data.dart';
import 'package:json_annotation/json_annotation.dart';

import 'book.dart';
import 'familia.dart';

part 'house.g.dart';

@JsonSerializable()
@DataRepository([], remote: false)
class House extends DataModel<House> {
  @override
  final String? id;
  final String address;
  @DataRelationship(inverse: 'residence')
  final BelongsTo<Familia> owner;

  // on purpose does not have a default
  // (freezed models can't have and need to test everything)
  @DataRelationship(serialize: false)
  final HasMany<Book>? currentLibrary;

  // self-referential relationship
  @DataRelationship(serialize: false)
  late BelongsTo<House> house = asBelongsTo;

  House({
    this.id,
    required this.address,
    BelongsTo<Familia>? owner,
    this.currentLibrary,
  }) : owner = owner ?? BelongsTo();

  @override
  bool operator ==(other) =>
      other is House && id == other.id && address == other.address;

  @override
  int get hashCode => runtimeType.hashCode ^ id.hashCode ^ address.hashCode;

  @override
  String toString() => address;
}
