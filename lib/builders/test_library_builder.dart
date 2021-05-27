// ignore_for_file: prefer_interpolation_to_compose_strings

import 'dart:async';

import 'package:flutter_data/flutter_data.dart';
import 'package:build/build.dart';
import 'package:flutter_data/builders/utils.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as path_helper;

Builder testExtensionBuilder(options) => TestExtensionBuilder();

class TestExtensionBuilder implements Builder {
  static const testDir = 'test';
  @override
  final buildExtensions = const {
    r'$test$': ['test.data.dart']
  };

  @override
  Future<void> build(BuildStep b) async {
    final finalAssetId = AssetId(b.inputId.package, '$testDir/test.data.dart');
    final testPath = path_helper.join(b.inputId.package, testDir);

    final _classes = [
      await for (final file in b.findAssets(Glob('**/*.info')))
        await b.readAsString(file)
    ];

    final imports = _classes
        .map((s) {
          final assetUri = Uri.parse(s.split('#')[1]);
          if (assetUri.scheme == 'asset') {
            final relativePath =
                path_helper.relative(assetUri.path, from: testPath);
            return 'import \'$relativePath\';';
          }
          return 'import \'$assetUri\';';
        })
        .toSet()
        .join('\n');

    final adapters = _classes.map((s) {
      final className = s.split('#')[0];
      return '''
// ignore: must_be_immutable
class \$Test${className}LocalAdapter = \$${className}HiveLocalAdapter
    with TestHiveLocalAdapter<$className>;
class Test${className}RemoteAdapter = \$${className}RemoteAdapter with TestRemoteAdapter;
''';
    }).join('\n\n');

    final overrides = _classes.map((s) {
      final className = s.split('#')[0];
      final classType = DataHelpers.getType(className);
      return '''
${classType}LocalAdapterProvider.overrideWithProvider(Provider((ref) =>
    \$Test${className}LocalAdapter(ref))),
${classType}RemoteAdapterProvider.overrideWithProvider(Provider((ref) =>
    Test${className}RemoteAdapter(ref.read(${classType}LocalAdapterProvider)))),
''';
    }).join('\n');

    final importMockito = await isDependency('mockito', b, dev: true);

    if (!importMockito) {
      return null;
    }

    await b.writeAsString(finalAssetId, '''\n
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: directives_ordering, top_level_function_literal_block

import 'dart:async';

import 'package:flutter_data/flutter_data.dart';
import 'package:hive/hive.dart';
import 'package:http/testing.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;

$imports

// test support

$adapters

final flutterDataTestOverrides = [
  hiveLocalStorageProvider
    .overrideWithProvider(Provider((_) => TestHiveLocalStorage())),
  graphNotifierProvider.overrideWithProvider(Provider(
    (ref) => TestDataGraphNotifier(ref.read(hiveLocalStorageProvider)))),
  $overrides
];

// fakes, mocks & mixins

class FakeBox<T> extends Fake implements Box<T> {
  final _map = <dynamic, T>{};

  @override
  bool isOpen = false;

  @override
  T get(key, {T defaultValue}) {
    return _map[key] ?? defaultValue;
  }

  @override
  Future<void> put(key, T value) async {
    _map[key] = value;
  }

  @override
  Future<void> putAll(Map<dynamic, T> entries) async {
    for (final key in entries.keys) {
      await put(key, entries[key]);
    }
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
    await super.initialize();
    box = FakeBox<Map>();
    return this;
  }
}

class TestDataGraphNotifier = GraphNotifier with TestMetaBox;

class TestHiveLocalStorage extends HiveLocalStorage {
  @override
  HiveInterface get hive => HiveMock();

  @override
  HiveAesCipher get encryptionCipher => null;

  @override
  Future<String> Function() get baseDirFn => () async => '';
}

mixin TestHiveLocalAdapter<T extends DataModel<T>> on HiveLocalAdapter<T> {
  @override
  // ignore: must_call_super
  Future<TestHiveLocalAdapter<T>> initialize() async {
    await super.initialize();
    box = FakeBox<T>();
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
      return ref.watch(mockResponseProvider(req));
    });
  }
}

final mockResponseProvider =
    Provider.family<http.Response, http.Request>((ref, req) {
  throw UnsupportedError('Please override mockResponseProvider!');
});

''');
  }
}
