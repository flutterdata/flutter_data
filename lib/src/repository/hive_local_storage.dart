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
  return ProviderScope(
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
    hive..init(path);

    _isInitialized = true;
    return this;
  }
}

final hiveLocalStorageProvider =
    Provider<HiveLocalStorage>((ref) => HiveLocalStorage());
