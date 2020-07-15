import 'package:flutter_data/flutter_data.dart';
import 'package:hive/hive.dart';

class WebHiveLocalStorage implements HiveLocalStorage {
  WebHiveLocalStorage(this.hive, List<int> encryptionKey, {this.clear})
      : encryptionCipher =
            encryptionKey != null ? HiveAesCipher(encryptionKey) : null;

  @override
  final HiveInterface hive;
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

HiveLocalStorage getHiveLocalStorage(ProviderReference ref,
    {HiveInterface hive, List<int> encryptionKey, bool clear}) {
  return WebHiveLocalStorage(hive, encryptionKey, clear: clear);
}
