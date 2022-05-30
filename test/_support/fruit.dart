// ignore_for_file: invalid_annotation_target

import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_data/flutter_data.dart';
import 'package:json_annotation/json_annotation.dart';

part 'fruit.g.dart';

class SetConverter {
  static Set<String> fromJson(String value) {
    return value.split(',').toSet();
  }

  static String toJson(Set<String> value) {
    return value.join(',');
  }
}

@JsonSerializable()
@DataRepository([], remote: false)
class Fruit extends DataModel<Fruit> with EquatableMixin {
  @override
  final Object? id;

  // isar supported types
  final int integer;
  final int? maybeInteger;
  final List<int?> listMaybeInteger;
  final List<int?>? maybeListMaybeInteger;

  final DateTime date;
  final DateTime? maybeDate;
  final List<DateTime?> listMaybeDate;
  final List<DateTime?>? maybeListMaybeDate;

  final String string;
  final String? maybeString;
  final List<String?> listMaybeString;
  final List<String?>? maybeListMaybeString;

  final bool boolean;
  final bool? maybeBoolean;
  final List<bool?> listMaybeBoolean;
  final List<bool?>? maybeListMaybeBoolean;

  // other jsonserializable supported types
  final BigInt bigInt;
  final Duration duration;

  @JsonKey(unknownEnumValue: Classification.inactive)
  Classification classification;
  Classification? classificationNoDefault;

  final Iterable iterable;
  final Map<String, dynamic> map;
  final Map<String, bool> boolMap;
  final Set<String> set;
  final Uri uri;

  // jsonserializable tojson
  @JsonKey(fromJson: SetConverter.fromJson, toJson: SetConverter.toJson)
  final Set<String> delimitedString;

  Fruit(
      {this.id,
      required this.bigInt,
      required this.duration,
      required this.iterable,
      required this.map,
      required this.boolMap,
      required this.set,
      required this.uri,
      required this.integer,
      this.maybeInteger,
      required this.listMaybeInteger,
      this.maybeListMaybeInteger,
      required this.date,
      this.maybeDate,
      required this.listMaybeDate,
      this.maybeListMaybeDate,
      required this.string,
      this.maybeString,
      required this.listMaybeString,
      this.maybeListMaybeString,
      required this.boolean,
      this.maybeBoolean,
      required this.listMaybeBoolean,
      this.maybeListMaybeBoolean,
      required this.delimitedString,
      required this.classification});

  @override
  String toString() {
    final encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(_$FruitToJson(this));
  }

  @override
  List<Object?> get props => [
        integer,
        maybeInteger,
        listMaybeInteger,
        maybeListMaybeInteger,
        date,
        maybeDate,
        listMaybeDate,
        maybeListMaybeDate,
        string,
        maybeString,
        listMaybeString,
        maybeListMaybeString,
        boolean,
        maybeBoolean,
        listMaybeBoolean,
        maybeListMaybeBoolean,
        bigInt,
        duration,
        classification,
        classificationNoDefault,
        iterable,
        map,
        boolMap,
        set,
        uri,
        delimitedString,
      ];
}

enum Classification {
  @JsonValue(0)
  none,

  @JsonValue(1)
  open,

  @JsonValue(2)
  inactive,

  @JsonValue(3)
  closed,
}
