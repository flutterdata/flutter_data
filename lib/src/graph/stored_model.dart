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

extension PackerX on Packer {
  void packJson(Map<String, dynamic> map) {
    packMapLength(map.length);
    map.forEach((key, v) {
      packString(key);
      packDynamic(v);
    });
  }

  void packIterableDynamic(Iterable iterable) {
    packListLength(iterable.length);
    for (final v in iterable) {
      packDynamic(v);
    }
  }

  void packDynamic(dynamic value) {
    if (value is Map) {
      packInt(5);
      return packJson(Map<String, dynamic>.from(value));
    }

    final type = value.runtimeType;
    if (type == Null) {
      packInt(0);
      return packNull();
    }
    if (type == String) {
      packInt(1);
      return packString(value);
    }
    if (type == int) {
      // WORKAROUND: for some reason negative ints are not working
      // so we save it as a special string (prefixed with $__fd_n:)
      if ((value as int).isNegative) {
        packInt(1);
        return packString('\$__fd_n:$value');
      }
      packInt(2);
      return packInt(value);
    }
    if (type == double) {
      packInt(3);
      return packDouble(value);
    }
    if (type == bool) {
      packInt(4);
      return packBool(value);
    }
    // List of any type
    if (value is Iterable) {
      packInt(6);
      return packIterableDynamic(value.toList());
    }
    throw Exception('missing type $type ($value)');
  }
}

extension UnpackerX on Unpacker {
  Map<String, dynamic> unpackJson() {
    final map = <String, dynamic>{};
    final length = unpackMapLength();
    for (var i = 0; i < length; i++) {
      final key = unpackString();
      map[key!] = unpackDynamic();
    }
    return map;
  }

  List unpackListDynamic() {
    final list = [];
    final length = unpackListLength();
    for (var i = 0; i < length; i++) {
      list.add(unpackDynamic());
    }
    return list;
  }

  dynamic unpackDynamic() {
    final type = unpackInt();
    switch (type) {
      case 0:
        return unpackString();
      case 1:
        final str = unpackString();
        // WORKAROUND: we unpack a negative int (encoded with the $__fd_n: prefix)
        if (str != null && str.startsWith('\$__fd_n:-')) {
          return int.parse(str.split(':').last);
        }
        return str;
      case 2:
        return unpackInt();
      case 3:
        return unpackDouble();
      case 4:
        return unpackBool();
      case 5:
        return unpackJson();
      case 6:
        return unpackListDynamic();
      default:
        throw Exception('missing type $type');
    }
  }
}
