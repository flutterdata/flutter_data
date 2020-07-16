import 'dart:async';

import 'package:hive/hive.dart';
import 'package:riverpod/riverpod.dart';

// ignore_for_file: unused_import
import 'hive_local_storage_web.dart'
    if (dart.library.io) 'hive_local_storage_io.dart';

typedef BaseDirFn = FutureOr<String> Function();

abstract class HiveLocalStorage {
  factory HiveLocalStorage(
      {BaseDirFn baseDirFn, List<int> encryptionKey, bool clear}) {
    return getHiveLocalStorage(
        baseDirFn: baseDirFn, encryptionKey: encryptionKey, clear: clear);
  }

  HiveAesCipher get encryptionCipher;
  HiveInterface get hive;

  Future<void> initialize();
}

final hiveLocalStorageProvider =
    Provider<HiveLocalStorage>((ref) => HiveLocalStorage());
