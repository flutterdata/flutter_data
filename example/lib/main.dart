import 'dart:io';
import 'package:flutter_data/flutter_data.dart';

import 'main.data.dart';
import 'models/user.dart';

// NOTE: FOR AN UPDATED AND COMPLETE FLUTTER EXAMPLE FOLLOW
// https://github.com/flutterdata/tutorial

void main() async {
  late final Directory _dir;

  try {
    final container = ProviderContainer(
      overrides: [
        localStorageProvider.overrideWith(
          (ref) => ObjectboxLocalStorage(
            baseDirFn: () => _dir.path,
            encryptionKey: _encryptionKey,
            clear: LocalStorageClearStrategy.always,
          ),
        ),
      ],
    );

    _dir = Directory.systemTemp.createTempSync();
    print('Using temporary directory: ${_dir.path}');
    _dir.deleteSync(recursive: true);

    await container.read(repositoryInitializerProvider.future);

    container.users.logLevel = 2;
    container.tasks.logLevel = 2;

    await container.tasks.findAll(params: {'user_id': 1, '_limit': 3});

    final user = User(id: 1, name: 'Roman').saveLocal();
    final user2 = await container.users.findOne(1, remote: false);

    assert(user.name == user2!.name);
    assert(user.tasks.length == 3);
  } finally {
    _dir.deleteSync(recursive: true);
  }
}

const String _encryptionKey = '_encryptionKey';
