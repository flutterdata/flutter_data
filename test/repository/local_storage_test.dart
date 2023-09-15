@OnPlatform({
  'js': Skip(),
})

import 'dart:io';

import 'package:flutter_data/flutter_data.dart';
import 'package:hive/hive.dart';
import 'package:test/test.dart';

void main() async {
  test('hive local storage', () async {
    late final Directory dir;

    dir = await Directory('tmp').create();
    final storage = HiveLocalStorage(
      baseDirFn: () => dir.path,
      encryptionKey: '_encryptionKey',
      clear: LocalStorageClearStrategy.always,
    );
    await storage.initialize();

    expect(() {
      return HiveLocalStorage(
        baseDirFn: null,
        encryptionKey: '_encryptionKey',
        clear: LocalStorageClearStrategy.never,
      ).initialize();
    }, throwsA(isA<UnsupportedError>()));
  });

  test('hive local storage clear when error', () async {
    late final Directory dir;

    dir = await Directory('tmp').create();
    final storage = HiveLocalStorage(
      baseDirFn: () => dir.path,
      clear: LocalStorageClearStrategy.whenError,
    );
    await storage.initialize();

    expect(() async {
      Hive.box(name: '_error');
    }, throwsA(isA<Error>()));
  });
}
