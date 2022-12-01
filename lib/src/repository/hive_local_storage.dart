import 'dart:async';

import 'package:flutter_data/flutter_data.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart' as path_helper;
import 'package:recase/recase.dart';

class HiveLocalStorage {
  HiveLocalStorage({
    required this.hive,
    this.baseDirFn,
    List<int>? encryptionKey,
    LocalStorageClearStrategy? clear,
  })  : encryptionCipher =
            encryptionKey != null ? HiveAesCipher(encryptionKey) : null,
        clear = clear ?? LocalStorageClearStrategy.never;

  final HiveInterface hive;
  final HiveAesCipher? encryptionCipher;
  final FutureOr<String> Function()? baseDirFn;
  final LocalStorageClearStrategy clear;
  late final String path;

  final _boxes = <String>[];

  bool isInitialized = false;

  Future<void> initialize() async {
    if (isInitialized) return;

    if (baseDirFn == null) {
      throw UnsupportedError('''
A base directory path MUST be supplied to
the hiveLocalStorageProvider via the `baseDirFn`
callback.

In Flutter, `baseDirFn` will be supplied automatically if
the `path_provider` package is in `pubspec.yaml` AND
Flutter Data is properly configured:

Did you supply the override?

Widget build(context) {
  return ProviderContainer(
    overrides: [
      configureRepositoryLocalStorage()
    ],
    child: MaterialApp(
''');
    }

    path = path_helper.join(await baseDirFn!(), 'flutter_data');
    hive.init(path);

    isInitialized = true;
  }

  Future<Box<B>> openBox<B>(String name, {bool retry = true}) async {
    // start using snake_case name only if box
    // does not exist in order not to break present boxes
    if (!await hive.boxExists(name)) {
      // since the snakeCase function strips leading _'s
      // we capture them restore them afterwards
      final matches = RegExp(r'^(_+)[a-z]').allMatches(name);
      name = ReCase(name).snakeCase;
      if (matches.isNotEmpty) {
        name = matches.first.group(1)! + name;
      }
    }
    _boxes.add(name);
    try {
      return await hive.openBox<B>(name, encryptionCipher: encryptionCipher);
    } on HiveError catch (_) {
      if (clear == LocalStorageClearStrategy.whenError && retry) {
        // if box is corrupted, remove and open a new one (retry only once)
        await deleteBox(name);
        return await openBox(name, retry: false);
      } else {
        rethrow;
      }
    }
  }

  Future<void> deleteBox(String name) async {
    // if hard clear, remove box
    try {
      if (await hive.boxExists(name)) {
        _boxes.remove(name);
        await hive.deleteBoxFromDisk(name);
      }
      // now try with the new snake_case name
      name = ReCase(name).snakeCase;
      if (await hive.boxExists(name)) {
        _boxes.remove(name);
        await hive.deleteBoxFromDisk(name);
      }
    } catch (e) {
      // weird fs bug? where even after checking for file.exists()
      // in Hive, it throws a No such file or directory error
      if (e.toString().contains('No such file or directory')) {
        // we can safely ignore?
      } else {
        rethrow;
      }
    }
  }

  Future<void> destroy() async {
    final futures = [
      for (final boxName in _boxes) hive.deleteBoxFromDisk(boxName),
    ];
    await Future.wait(futures);
  }
}

enum LocalStorageClearStrategy {
  always,
  never,
  whenError,
}

final hiveLocalStorageProvider = Provider<HiveLocalStorage>(
  (ref) => HiveLocalStorage(hive: ref.read(hiveProvider), baseDirFn: () => ''),
);

final hiveProvider = Provider<HiveInterface>((_) => Hive);
