

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: directives_ordering

import 'dart:io';
import 'package:flutter_data/flutter_data.dart';


import 'package:jsonplaceholder_example/model/post.dart';
import 'package:jsonplaceholder_example/model/user.dart';
import 'package:jsonplaceholder_example/model/comment.dart';

extension FlutterData on DataManager {

  static Future<DataManager> init(Directory baseDir, {bool autoModelInit = true, bool clear, bool remote, bool verbose, List<int> encryptionKey, Function(void Function<R>(R)) also}) async {
    assert(baseDir != null);

    final injection = DataServiceLocator();

    final manager = await DataManager(autoModelInit: autoModelInit).init(baseDir, injection.locator, clear: clear, verbose: verbose);
    injection.register(manager);
    final postLocalAdapter = await $PostLocalAdapter(manager, encryptionKey: encryptionKey).init();
    injection.register(postLocalAdapter);
    injection.register<Repository<Post>>($PostRepository(postLocalAdapter, remote: remote, verbose: verbose));

    final userLocalAdapter = await $UserLocalAdapter(manager, encryptionKey: encryptionKey).init();
    injection.register(userLocalAdapter);
    injection.register<Repository<User>>($UserRepository(userLocalAdapter, remote: remote, verbose: verbose));

    final commentLocalAdapter = await $CommentLocalAdapter(manager, encryptionKey: encryptionKey).init();
    injection.register(commentLocalAdapter);
    injection.register<Repository<Comment>>($CommentRepository(commentLocalAdapter, remote: remote, verbose: verbose));


    if (also != null) {
      // ignore: unnecessary_lambdas
      also(<R>(R obj) => injection.register<R>(obj));
    }

    return manager;

}

  
  
}


