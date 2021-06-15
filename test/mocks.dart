import 'dart:async';

import 'package:hive/hive.dart';
import 'package:flutter_data/flutter_data.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;

import 'package:http/testing.dart';

// EXACT SAME CODE AS THE TEST BUILDER - KEEP IN SYNC FOR NOW

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
  Future<void> close() => Future.value();
}

class HiveMock extends Mock implements HiveInterface {
  @override
  bool isBoxOpen(String name) => true;

  @override
  void init(String path) {
    return;
  }
}

class Listener<T> extends Mock {
  void call(T value);
}

mixin TestMetaBox on GraphNotifier {
  @override
  // ignore: must_call_super
  Future<GraphNotifier> initialize() async {
    box = FakeBox<Map>();
    await super.initialize();
    return this;
  }
}

class TestDataGraphNotifier = GraphNotifier with TestMetaBox;

class TestHiveLocalStorage extends HiveLocalStorage {
  @override
  HiveInterface get hive => HiveMock();

  @override
  HiveAesCipher? get encryptionCipher => null;

  @override
  Future<String> Function() get baseDirFn => () async => '';
}

mixin TestHiveLocalAdapter<T extends DataModel<T>> on HiveLocalAdapter<T> {
  @override
  // ignore: must_call_super
  Future<TestHiveLocalAdapter<T>> initialize() async {
    box = FakeBox<T>();
    await super.initialize();
    return this;
  }
}

mixin TestRemoteAdapter<T extends DataModel<T>> on RemoteAdapter<T> {
  @override
  Duration get throttleDuration => Duration.zero;

  @override
  String get baseUrl => '';

  @override
  http.Client get httpClient {
    return MockClient((req) async {
      try {
        return ref!.watch(mockResponseProvider(req));
      } on ProviderException catch (e) {
        // unwrap provider exception
        // ignore: only_throw_errors
        throw e.exception;
      }
    });
  }
}

final mockResponseProvider =
    Provider.family<http.Response, http.Request>((ref, req) {
  throw UnsupportedError('Please override mockResponseProvider!');
});
