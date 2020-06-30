import 'dart:io';
import 'package:flutter_data/flutter_data.dart';

import 'main.data.dart';
import 'model/comment.dart';
import 'model/post.dart';
import 'model/user.dart';

// NOTE: FOR AN UPDATED AND COMPLETE FLUTTER EXAMPLE FOLLOW
// https://github.com/flutterdata/flutter_data_todos

void main() async {
  Directory _dir;

  try {
    _dir = await Directory('tmp').create();
    await _dir.delete(recursive: true);

    final manager = await FlutterData.init(_dir,
        verbose: true, encryptionKey: _encryptionKey);
    final locator = manager.locator;

    final usersRepo = locator<Repository<User>>();
    final postsRepo = locator<Repository<Post>>();
    final commentsRepo = locator<Repository<Comment>>();
    User user;

    try {
      user = await usersRepo.findOne('2314444');
    } on DataException catch (e) {
      if (e.status == HttpStatus.notFound) {
        print('not found');
      }
    }

    var user2 = User(id: 1, name: 'new name', email: 'new@fasd.io');
    await user2.save();

    User(id: 1, name: 'new name', email: 'new@fasd.io');

    var p3 = Post(
            id: 102,
            title: 'new name',
            body: '3@fasd.io',
            user: user2.asBelongsTo,
            comments: {Comment(id: 1, body: 'bla')}.asHasMany)
        .init();

    assert(p3.body == '3@fasd.io');
    assert(p3.user.value.email == user2.email);

    var post = await postsRepo.findOne(1, params: {'_embed': 'comments'});
    var comments = await commentsRepo.findAll(params: {'postId': 1});

    print(comments.map((c) => c.body).toList());

    assert(comments.first.post.value == post);
    assert(user.name == post.user.value.name);

    var stream = usersRepo.watchAll().stream;

    await for (final state in stream) {
      print(state.length);
    }
  } finally {
    await _dir.delete(recursive: true);
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
