import 'dart:async';
import 'dart:io';

import 'package:hive/hive.dart';
import 'package:path/path.dart' as path_helper;

import 'hive_local_storage.dart';

class IoHiveLocalStorage implements HiveLocalStorage {
  IoHiveLocalStorage({this.baseDirFn, List<int> encryptionKey, this.clear})
      : encryptionCipher =
            encryptionKey != null ? HiveAesCipher(encryptionKey) : null;

  @override
  HiveInterface get hive => Hive;
  @override
  final HiveAesCipher encryptionCipher;
  final FutureOr<String> Function() baseDirFn;
  final bool clear;

  bool _isInitialized = false;

  @override
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

    final dir = Directory(await baseDirFn());
    final exists = await dir.exists();
    if ((clear ?? true) && exists) {
      await dir.delete(recursive: true);
    }

    final path = path_helper.join(dir.path, 'flutter_data');
    hive..init(path);

    _isInitialized = true;
    return this;
  }
}

HiveLocalStorage getHiveLocalStorage(
    {FutureOr<String> Function() baseDirFn,
    List<int> encryptionKey,
    bool clear}) {
  return IoHiveLocalStorage(
      baseDirFn: baseDirFn, encryptionKey: encryptionKey, clear: clear);
}
