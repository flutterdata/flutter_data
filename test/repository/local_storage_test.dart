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

    await storage.openBox('posts');

    expect(await hive.boxExists('posts'), isTrue);
    expect(await hive.boxExists('comments'), isFalse);

    await storage.deleteBox('posts');
    expect(await hive.boxExists('posts'), isFalse);

    // now with underscore special case
    await storage.openBox('_authors');
    await storage.deleteBox('_authors');
    expect(await hive.boxExists('_authors'), isFalse);

    // and with snake case conversion
    await storage.openBox('authors_meta');
    await storage.deleteBox('authorsMeta');
    expect(await hive.boxExists('authors_meta'), isFalse);

    await storage.openBox('libraries');

    await storage.destroy();

    for (final _ in ['posts', 'libraries']) {
      expect(await hive.boxExists(_), isFalse);
    }
  });
}
