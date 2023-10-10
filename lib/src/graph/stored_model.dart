import 'package:flutter_data/flutter_data.dart';
import 'package:isar/isar.dart';
import 'package:messagepack/messagepack.dart';

part 'stored_model.g.dart';

@collection
class StoredModel {
  const StoredModel({
    required this.key,
    required this.type,
    this.id,
    this.isIdInt = false,
    this.data,
  });

  @Id()
  final int key;

  @Index(hash: true, composite: ['type'])
  final String? id;

  final bool isIdInt;

  final String type;

  final List<byte>? data;

  Map<String, dynamic>? toJson() {
    if (data == null) {
      return null;
    }
    final unpacker = Unpacker.fromList(data!);
    final map = unpacker.unpackJson();

    return {
      'id': id,
      '_key': key,
      ...map,
    };
  }

  @override
  String toString() {
    return '<StoredModel>${toJson()}';
  }
}
