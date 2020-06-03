import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:flutter_data/flutter_data.dart';
import 'package:flutter_data/annotations.dart';
import 'family.dart';

part 'house.g.dart';

@JsonSerializable()
@DataRepository([])
class House with DataSupportMixin<House> {
  @override
  final String id;
  final String address;
  @DataRelationship(inverse: 'residence')
  final BelongsTo<Family> owner;

  House({
    this.id,
    @required this.address,
    BelongsTo<Family> owner,
  }) : owner = owner ?? BelongsTo();

  @override
  String toString() => address;
}
