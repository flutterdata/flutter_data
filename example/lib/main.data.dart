// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: directives_ordering

import 'dart:io';
import 'package:flutter_data/flutter_data.dart';

import 'package:jsonplaceholder_example/model/post.dart';
import 'package:jsonplaceholder_example/model/user.dart';
import 'package:jsonplaceholder_example/model/comment.dart';

extension FlutterData on DataManager {
  static Future<DataManager> init(Directory baseDir,
      {bool enableAutoManager = true,
      bool clear,
      bool remote,
      bool verbose,
      List<int> encryptionKey,
      Function(void Function<R>(R)) also}) async {
    assert(baseDir != null);

    final injection = DataServiceLocator();

    final manager = await DataManager(enableAutoManager: enableAutoManager)
        .init(baseDir, injection.locator, clear: clear, verbose: verbose);
    injection.register(manager);

    final postRepository =
        $PostRepository(manager, remote: remote, verbose: verbose);
    injection.register<Repository<Post>>(postRepository);
    final postBox =
        await Repository.getBox<Post>(manager, encryptionKey: encryptionKey);
    injection.register(postBox);

    final userRepository =
        $UserRepository(manager, remote: remote, verbose: verbose);
    injection.register<Repository<User>>(userRepository);
    final userBox =
        await Repository.getBox<User>(manager, encryptionKey: encryptionKey);
    injection.register(userBox);

    final commentRepository =
        $CommentRepository(manager, remote: remote, verbose: verbose);
    injection.register<Repository<Comment>>(commentRepository);
    final commentBox =
        await Repository.getBox<Comment>(manager, encryptionKey: encryptionKey);
    injection.register(commentBox);

    if (also != null) {
      // ignore: unnecessary_lambdas
      also(<R>(R obj) => injection.register<R>(obj));
    }
    await postRepository.initialize();
    await userRepository.initialize();
    await commentRepository.initialize();

    return manager;
  }
}
