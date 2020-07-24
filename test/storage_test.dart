import 'dart:io';

import 'package:flutter_data/storage/hive_local_storage_io.dart';
import 'package:hive/hive.dart';
import 'package:test/test.dart';

void main() async {
  test('hive local storage (io)', () async {
    Directory _dir;

    try {
      _dir = await Directory('tmp').create();
      final storage = getHiveLocalStorage(
          baseDirFn: () => _dir.path,
          encryptionKey: Hive.generateSecureKey(),
          clear: true);
      await storage.initialize();
      expect(storage.encryptionCipher, isA<HiveAesCipher>());

      expect(() {
        return getHiveLocalStorage(
                baseDirFn: null,
                encryptionKey: Hive.generateSecureKey(),
                clear: false)
            .initialize();
      }, throwsA(isA<UnsupportedError>()));
    } finally {
      if (_dir.existsSync()) {
        await _dir.delete(recursive: true);
      }
    }
  });
}
