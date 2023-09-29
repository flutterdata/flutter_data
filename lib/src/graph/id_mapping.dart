import 'package:isar/isar.dart';

part 'id_mapping.g.dart';

@collection
class IdMapping {
  IdMapping({required this.key, required this.id, this.isInt = false});

  @Id()
  int get isarId => Isar.fastHash(key);

  final String key;

  @Index()
  final String id;

  final bool isInt;

  @override
  String toString() {
    return '{ key: $key => id: $id }';
  }
}
