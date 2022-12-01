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
        configureRepositoryLocalStorage(
          baseDirFn: () => _dir.path,
          encryptionKey: _encryptionKey,
          clear: LocalStorageClearStrategy.always,
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

    final user = User(id: 19, name: 'Zeku');
    final user2 = await container.users.findOne(19, remote: false);

    assert(user == user2);
    assert(user.tasks.length == 3);
  } finally {
    _dir.deleteSync(recursive: true);
  }
}

const List<int> _encryptionKey = [
  146,
  54,
  40,
  58,
  46,
  90,
  152,
  02,
  193,
  210,
  220,
  199,
  16,
  96,
  107,
  4,
  243,
  133,
  171,
  31,
  241,
  26,
  149,
  53,
  172,
  36,
  121,
  103,
  17,
  155,
  120,
  61
];
