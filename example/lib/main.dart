import 'dart:io';
import 'package:flutter_data/flutter_data.dart';

import 'main.data.dart';
import 'model/comment.dart';
import 'model/post.dart';
import 'model/user.dart';

// NOTE: FOR A COMPLETE FLUTTER EXAMPLE PLEASE SEE
// https://github.com/flutterdata/flutter_data_todos

void main() async {
  Directory _dir;

  try {
    _dir = await Directory('../tmp').create();
    final manager = await FlutterData.init(_dir);
    final locator = manager.locator;

    Repository<User> usersRepo = locator<Repository<User>>();
    Repository<Post> postsRepo = locator<Repository<Post>>();
    User user;

    try {
      user = await usersRepo.findOne('1');
    } on DataException catch (e) {
      if (e.status == HttpStatus.notFound) {
        print('not found');
      }
    }

    var user2 = User(id: 102, name: 'new name', email: 'new@fasd.io');
    await user2.save();

    User(id: 102, name: 'new name', email: 'new@fasd.io');

    var p3 = Post(
        id: 102,
        title: 'new name',
        body: '3@fasd.io',
        user: user2.asBelongsTo,
        comments: [Comment(id: 1, body: 'bla')].asHasMany);

    assert(p3.body == '3@fasd.io');
    assert(p3.user.value.email == user2.email);

    var post = await postsRepo.findOne('1', params: {'_embed': 'comments'});

    print(post.comments.map((c) => c.body));

    assert(user.name == post.user.value.name);

    var stream = usersRepo.watchAll().stream;

    await for (var state in stream) {
      print(state.length);
    }
  } finally {
    await _dir.delete(recursive: true);
  }
}
