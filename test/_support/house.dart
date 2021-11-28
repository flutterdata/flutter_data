import 'package:flutter_data/flutter_data.dart';
import 'package:json_annotation/json_annotation.dart';

import 'family.dart';

part 'house.g.dart';

@JsonSerializable()
@DataRepository([])
class House with DataModel<House> {
  @override
  final String? id;
  final String address;
  @DataRelationship(inverse: 'residence')
  final BelongsTo<Family> owner;

  House({
    this.id,
    required this.address,
    BelongsTo<Family>? owner,
  }) : owner = owner ?? BelongsTo();

  @override
  bool operator ==(other) =>
      other is House && id == other.id && address == other.address;

  @override
  int get hashCode => runtimeType.hashCode ^ id.hashCode ^ address.hashCode;

  @override
  String toString() => address;
}
