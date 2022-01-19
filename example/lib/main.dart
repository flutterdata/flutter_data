import 'dart:io';
import 'package:flutter_data/flutter_data.dart';

import 'main.data.dart';
import 'models/user.dart';

// NOTE: FOR AN UPDATED AND COMPLETE FLUTTER EXAMPLE FOLLOW
// https://github.com/flutterdata/tutorial

void main() async {
  late final Directory _dir;
  final container = ProviderContainer(
    overrides: [
      configureRepositoryLocalStorage(
        baseDirFn: () => _dir.path,
        encryptionKey: _encryptionKey,
      ),
    ],
  );

  try {
    _dir = await Directory('tmp').create();
    _dir.deleteSync(recursive: true);

    await container.read(repositoryInitializerProvider().future);

    final usersRepo = container.read(usersRepositoryProvider);
    final user =
        await usersRepo.findOne(1, params: {'_embed': 'tasks', '_limit': 5});
    assert(user!.tasks.length == 5);
  } finally {
    if (_dir.existsSync()) {
      _dir.deleteSync(recursive: true);
    }
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
