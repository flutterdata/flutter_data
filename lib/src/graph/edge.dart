import 'package:objectbox/objectbox.dart';

@Entity()
class Edge {
  Edge(
      {required this.id,
      required this.from,
      required this.name,
      required this.to,
      this.inverseName});

  @Id()
  int id;

  // @Index(hash: true, composite: ['name'])
  @Index(type: IndexType.hash)
  final String from;
  final String name;

  // @Index(hash: true, composite: ['name'])
  @Index(type: IndexType.hash)
  final String to;
  final String? inverseName;

  @override
  String toString() {
    return '{ $from <---$name($inverseName)---> $to}';
  }
}