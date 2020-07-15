import 'dart:async';
import 'dart:io';

import 'package:hive/hive.dart';
import 'package:path/path.dart' as path_helper;
import 'package:riverpod/riverpod.dart';

import 'hive_local_storage.dart';

class IoHiveLocalStorage implements HiveLocalStorage {
  IoHiveLocalStorage(this._ref, this.hive, List<int> encryptionKey,
      {this.clear})
      : encryptionCipher =
            encryptionKey != null ? HiveAesCipher(encryptionKey) : null;

  @override
  final HiveInterface hive;
  @override
  final HiveAesCipher encryptionCipher;
  final ProviderReference _ref;
  final bool clear;

  bool _isInitialized = false;

  @override
  Future<void> initialize() async {
    if (_isInitialized || _ref == null) return this;

    final dir = Directory(await _ref.read(hiveDirectoryProvider));
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

HiveLocalStorage getHiveLocalStorage(ProviderReference ref,
    {HiveInterface hive, List<int> encryptionKey, bool clear}) {
  return IoHiveLocalStorage(ref, hive, encryptionKey, clear: clear);
}
