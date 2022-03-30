import 'dart:async';
import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:hive/src/box/default_compaction_strategy.dart';
import 'package:hive/src/box/default_key_comparator.dart';
import 'package:mockito/mockito.dart';

class FakeBox<T> extends Fake implements Box<T> {
  final _map = <dynamic, T>{};

  @override
  bool isOpen = true;

  @override
  T? get(key, {T? defaultValue}) {
    return _map[key] ?? defaultValue;
  }

  @override
  Future<void> put(key, T value) async {
    _map[key] = value;
  }

  @override
  Future<void> delete(key) async {
    _map.remove(key);
  }

  @override
  Map<dynamic, T> toMap() => _map;

  @override
  Iterable get keys => _map.keys;

  @override
  Iterable<T> get values => _map.values;

  @override
  bool containsKey(key) => _map.containsKey(key);

  @override
  int get length => _map.length;

  @override
  Future<void> deleteFromDisk() async {
    await clear();
  }

  @override
  bool get isEmpty => length == 0;

  @override
  bool get isNotEmpty => !isEmpty;

  @override
  Future<int> clear() {
    _map.clear();
    return Future.value(0);
  }

  @override
  Future<void> close() async {
    isOpen = false;
  }
}

class HiveFake extends Fake implements HiveInterface {
  @override
  bool isBoxOpen(String name) => true;

  @override
  void init(String path) {}

  @override
  Future<bool> boxExists(String name, {String? path}) async => false;

  @override
  Future<Box<E>> openBox<E>(
    String name, {
    HiveCipher? encryptionCipher,
    KeyComparator keyComparator = defaultKeyComparator,
    CompactionStrategy compactionStrategy = defaultCompactionStrategy,
    bool crashRecovery = true,
    String? path,
    Uint8List? bytes,
    @Deprecated('Use encryptionCipher instead') List<int>? encryptionKey,
  }) async {
    return FakeBox<E>();
  }
}

class Listener<T> extends Mock {
  void call(T value);
}
