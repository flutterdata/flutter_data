import 'package:equatable/equatable.dart';
import 'package:flutter_data/flutter_data.dart';
import 'package:messagepack/messagepack.dart';
import 'package:objectbox/objectbox.dart';

@Entity()
class StoredModel with EquatableMixin {
  StoredModel({
    required this.key,
    required this.typeId,
    this.data,
  });

  @Id(assignable: true)
  int key;

  @Index(type: IndexType.value)
  final String typeId;

  final List<int>? data;

  String get type {
    return typeId.split('#')[0];
  }

  Map<String, dynamic>? toJson() {
    if (data == null) {
      return null;
    }
    final unpacker = Unpacker.fromList(data!);
    final map = unpacker.unpackJson();
    // ignore: unnecessary_nullable_for_final_variable_declarations
    final id = typeId.detypify();

    return {
      'id': id,
      '_key': key,
      ...map,
    };
  }

  @override
  List<Object?> get props => [key];

  @override
  String toString() {
    return '<StoredModel k:$key t:$typeId>${toJson()}';
  }
}
