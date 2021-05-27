import 'dart:async';

import 'package:hive/hive.dart';
import 'package:riverpod/riverpod.dart';
import 'package:path/path.dart' as path_helper;

class HiveLocalStorage {
  HiveLocalStorage(
      {this.baseDirFn, List<int> encryptionKey, this.clear = false})
      : encryptionCipher =
            encryptionKey != null ? HiveAesCipher(encryptionKey) : null;

  HiveInterface get hive => Hive;
  final HiveAesCipher encryptionCipher;
  final FutureOr<String> Function() baseDirFn;
  final bool clear;

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return this;

    if (baseDirFn == null) {
      throw UnsupportedError('''
A base directory path MUST be supplied to
the hiveLocalStorageProvider via the `baseDirFn`
callback.

In Flutter, `baseDirFn` will be supplied automatically if
the `path_provider` package is in `pubspec.yaml` AND
Flutter Data is properly configured:

If using Riverpod, did you supply the override?

Widget build(context) {
  return ProviderContainer(
    overrides: [
      configureRepositoryLocalStorage()
    ],
    child: MaterialApp(

If using Provider, did you include the providers?

Widget build(context) {
  return MultiProvider(
    providers: [
      ...repositoryProviders(),
    ],
    child: MaterialApp(
''');
    }

    final path = path_helper.join(await baseDirFn(), 'flutter_data');
    hive.init(path);

    _isInitialized = true;
    return this;
  }

  Future<Box<B>> openBox<B>(String name) async {
    return await hive.openBox<B>(name, encryptionCipher: encryptionCipher);
  }

  Future<void> deleteBox(String name) async {
    // if hard clear, remove box
    try {
      if (await hive.boxExists(name)) {
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
}

final hiveLocalStorageProvider =
    Provider<HiveLocalStorage>((ref) => HiveLocalStorage());
