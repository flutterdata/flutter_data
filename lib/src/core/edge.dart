import 'package:equatable/equatable.dart';
import 'package:flutter_data/flutter_data.dart';
import 'package:objectbox/objectbox.dart';

@Entity()
class Edge with EquatableMixin {
  Edge(
      {required this.from,
      required this.name,
      required this.to,
      this.inverseName})
      : internalKey = getInternalKey(from, name, to);

  static int getInternalKey(String from, String name, String to) =>
      DataHelpers.fastHash('$from:$name:$to');

  @Id(assignable: true)
  int internalKey;

  @Index(type: IndexType.hash)
  final String from;
  final String name;

  @Index(type: IndexType.hash)
  final String to;
  final String? inverseName;

  @override
  String toString() {
    return '{ [edgekey: $internalKey] $from <--- $name/$inverseName ---> $to}';
  }

  @override
  List<Object?> get props => [from, name, to];
}
