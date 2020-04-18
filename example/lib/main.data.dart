

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: directives_ordering

import 'dart:io';
import 'package:flutter_data/flutter_data.dart';


import 'package:jsonplaceholder_example/model/post.dart';
import 'package:jsonplaceholder_example/model/user.dart';
import 'package:jsonplaceholder_example/model/comment.dart';

extension FlutterData on DataManager {

  static Future<DataManager> init(Directory baseDir, {bool autoModelInit = true, bool clear = true, Function(void Function<R>(R)) also}) async {
    assert(baseDir != null);

    final injection = DataServiceLocator();

    final manager = await DataManager(autoModelInit: autoModelInit).init(baseDir, injection.locator, clear: clear);
    injection.register(manager);
    final postLocalAdapter = await $PostLocalAdapter(manager).init();
    injection.register(postLocalAdapter);
    injection.register<Repository<Post>>($PostRepository(postLocalAdapter));

    final userLocalAdapter = await $UserLocalAdapter(manager).init();
    injection.register(userLocalAdapter);
    injection.register<Repository<User>>($UserRepository(userLocalAdapter));

    final commentLocalAdapter = await $CommentLocalAdapter(manager).init();
    injection.register(commentLocalAdapter);
    injection.register<Repository<Comment>>($CommentRepository(commentLocalAdapter));


    if (also != null) {
      // ignore: unnecessary_lambdas
      also(<R>(R obj) => injection.register<R>(obj));
    }

    return manager;

}

  
  
}


