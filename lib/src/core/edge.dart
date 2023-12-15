import 'package:equatable/equatable.dart';
import 'package:objectbox/objectbox.dart';

@Entity()
class Edge with EquatableMixin {
  Edge(
      {this.id = 0,
      required this.from,
      required this.name,
      required this.to,
      this.inverseName});

  @Id()
  int id;

  @Index(type: IndexType.hash)
  final String from;
  final String name;

  @Index(type: IndexType.hash)
  final String to;
  final String? inverseName;

  @override
  String toString() {
    return '{ $from <---$name($inverseName)---> $to}';
  }

  @override
  List<Object?> get props => [from, name, to];
}
