import 'dart:io';
import 'package:flutter_data/flutter_data.dart';
// import 'package:get_it/get_it.dart';
import 'package:riverpod/riverpod.dart';

import 'main.data.dart';
import 'models/comment.dart';
import 'models/post.dart';
import 'models/user.dart';

// NOTE: FOR AN UPDATED AND COMPLETE FLUTTER EXAMPLE FOLLOW
// https://github.com/flutterdata/flutter_data_todos

void main() async {
  Directory _dir;
  final owner = ProviderStateOwner(
    overrides: [
      configureRepositoryLocalStorage(
          baseDirFn: () => _dir.path, encryptionKey: _encryptionKey),
    ],
  );

  try {
    _dir = await Directory('tmp').create();
    await _dir.delete(recursive: true);

    // GetIt.instance.registerRepositories(
    //     baseDirFn: () => _dir.path, encryptionKey: _encryptionKey);

    // final usersRepo = await GetIt.instance.getAsync<Repository<User>>();
    // final postsRepo = await GetIt.instance.getAsync<Repository<Post>>();
    // final commentsRepo = await GetIt.instance.getAsync<Repository<Comment>>();

    await owner.ref.read(repositoryInitializerProvider());

    final usersRepo = usersRepositoryProvider.readOwner(owner);
    final postsRepo = postsRepositoryProvider.readOwner(owner);
    final commentsRepo = commentsRepositoryProvider.readOwner(owner);

    try {
      await usersRepo.findOne('2314444');
    } on DataException catch (e) {
      if (e.status == HttpStatus.notFound) {
        print('not found');
      }
    }

    final user2 = User(id: 1, name: 'new name', email: 'new@fasd.io')
        // .init();
        .init(owner);
    await user2.save();

    var p3 = Post(
            id: 102,
            title: 'new name',
            body: '3@fasd.io',
            user: user2.asBelongsTo,
            comments: {Comment(id: 1, body: 'bla')}.asHasMany)
        // .init();
        .init(owner);

    assert(p3.body == '3@fasd.io');
    assert(p3.user.value.email == user2.email);

    final post = await postsRepo.findOne(1, params: {'_embed': 'comments'});
    final comments = await commentsRepo.findAll(params: {'postId': 1});

    assert(comments
        .map((c) => c.id)
        .toSet()
        .difference(post.comments.map((c) => c.id).toSet())
        .isEmpty);

    assert(user2.name == p3.user.value.name);
    assert(comments.first.post.value == post);

    print(comments.map((c) => c.body).toList());
  } catch (err, stack) {
    print(err);
    print(stack);
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
