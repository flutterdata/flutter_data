import 'package:isar/isar.dart';

part 'edge.g.dart';

@collection
class Edge {
  Edge(
      {required this.id,
      required this.from,
      required this.name,
      required this.to,
      this.inverseName});

  @Id()
  final int id;

  @Index(hash: true, composite: ['name'])
  final String from;
  final String name;

  @Index(hash: true, composite: ['name'])
  final String to;
  final String? inverseName;

  @override
  String toString() {
    return '{ $from <---$name($inverseName)---> $to}';
  }
}
