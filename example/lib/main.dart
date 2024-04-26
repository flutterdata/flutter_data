import 'dart:io';
import 'package:flutter_data/flutter_data.dart';

import 'main.data.dart';
import 'models/user.dart';

// NOTE: FOR AN UPDATED AND COMPLETE FLUTTER EXAMPLE FOLLOW
// https://github.com/flutterdata/tutorial

void main() async {
  late final Directory _dir;
  late final ProviderContainer container;

  try {
    _dir = Directory.systemTemp.createTempSync();

    container = ProviderContainer(
      overrides: [
        localStorageProvider.overrideWithValue(
          LocalStorage(
            baseDirFn: () => _dir.path,
            clear: LocalStorageClearStrategy.always,
          ),
        ),
      ],
    );

    print('Using temporary directory: ${_dir.path}');

    await container.read(initializeFlutterData(adapterProvidersMap).future);
    container.users.logLevel = 2;
    container.tasks.logLevel = 2;

    await container.tasks.findAll(params: {'user_id': 1, '_limit': 3});

    final user = User(id: 1, name: 'Roman').saveLocal();
    final user2 = container.users.findOneLocalById(1);

    assert(user.name == user2!.name);
    assert(user.tasks.length == 3);
  } finally {
    await container.read(localStorageProvider).destroy();
  }
}
