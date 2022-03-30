@OnPlatform({
  'js': Skip(),
})

import 'dart:io';

import 'package:flutter_data/flutter_data.dart';
import 'package:hive/hive.dart';
import 'package:test/test.dart';

import '../mocks.dart';

void main() async {
  test('hive local storage', () async {
    late final Directory _dir;
    final hive = HiveFake();

    try {
      _dir = await Directory('tmp').create();
      final storage = HiveLocalStorage(
        baseDirFn: () => _dir.path,
        encryptionKey: Hive.generateSecureKey(),
        clear: true,
        hive: hive,
      );
      await storage.initialize();
      expect(storage.encryptionCipher, isA<HiveAesCipher>());

      expect(() {
        return HiveLocalStorage(
          hive: hive,
          baseDirFn: null,
          encryptionKey: Hive.generateSecureKey(),
          clear: false,
        ).initialize();
      }, throwsA(isA<UnsupportedError>()));
    } finally {
      if (_dir.existsSync()) {
        await _dir.delete(recursive: true);
      }
    }
  });
}
