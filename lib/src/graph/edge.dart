import 'package:isar/isar.dart';

part 'edge.g.dart';

@collection
class Edge {
  Edge(
      {required this.from,
      required this.name,
      required this.to,
      this.inverseName});

  int get id => Isar.fastHash('$from-$to-$name');
  // TODO restore, can't query fromNameEqualTo('f', 'n')
  @Index() // hash: true, composite: ['name']
  final String from;
  final String name;

  @Index() // hash: true, composite: ['inverseName']
  final String to;
  final String? inverseName;

  @override
  String toString() {
    return '{ $from <---$name($inverseName)---> $to}';
  }
}
