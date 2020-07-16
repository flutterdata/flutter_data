import 'package:flutter_data/flutter_data.dart';
import 'package:hive/hive.dart';

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
    {BaseDirFn baseDirFn, List<int> encryptionKey, bool clear}) {
  return WebHiveLocalStorage(encryptionKey: encryptionKey, clear: clear);
}
