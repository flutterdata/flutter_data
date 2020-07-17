import 'dart:async';

import 'package:hive/hive.dart';

import 'hive_local_storage.dart';

class WebHiveLocalStorage implements HiveLocalStorage {
  WebHiveLocalStorage({List<int> encryptionKey, this.clear})
      : encryptionCipher =
            encryptionKey != null ? HiveAesCipher(encryptionKey) : null;

  @override
  HiveInterface get hive => Hive;
  @override
  final HiveAesCipher encryptionCipher;
  final bool clear;

  bool _isInitialized = false;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return this;

    if (clear ?? true) {
      await hive.deleteFromDisk();
    }

    _isInitialized = true;
    return this;
  }
}

HiveLocalStorage getHiveLocalStorage(
    {FutureOr<String> Function() baseDirFn,
    List<int> encryptionKey,
    bool clear}) {
  return WebHiveLocalStorage(encryptionKey: encryptionKey, clear: clear);
}
