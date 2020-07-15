import 'package:hive/hive.dart';
import 'package:riverpod/riverpod.dart';

// ignore_for_file: unused_import

import 'hive_local_storage_web.dart'
    if (dart.library.io) 'hive_local_storage_io.dart';

abstract class HiveLocalStorage {
  factory HiveLocalStorage(ProviderReference ref,
      {HiveInterface hive, List<int> encryptionKey, bool clear}) {
    return getHiveLocalStorage(ref,
        hive: (hive ?? Hive), encryptionKey: encryptionKey, clear: clear);
  }
  Future<void> initialize();
  HiveAesCipher get encryptionCipher;
  HiveInterface get hive;
}

final hiveDirectoryProvider = FutureProvider<String>((_) async => null);

final hiveLocalStorageProvider =
    Provider<HiveLocalStorage>((ref) => HiveLocalStorage(ref));
