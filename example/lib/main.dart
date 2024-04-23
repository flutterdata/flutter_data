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
        localStorageProvider.overrideWith(
          (ref) => LocalStorage(
            baseDirFn: () => _dir.path,
            encryptionKey: 'blah',
            clear: LocalStorageClearStrategy.always,
          ),
        ),
      ],
    );

    print('Using temporary directory: ${_dir.path}');

    container.read(adapterProviders.notifier).state = adapterProvidersMap;
    await container.read(initializeAdapters.future);
    container.users.logLevel = 2;
    container.tasks.logLevel = 2;

    await container.tasks.findAll(params: {'user_id': 1, '_limit': 3});

    final user = User(id: 1, name: 'Roman').saveLocal();
    final user2 = container.users.findOneLocalById(1);

    assert(user.name == user2!.name);
    print(user.tasks.length); // TODO fix
  } finally {
    await container.read(localStorageProvider).destroy();
  }
}
