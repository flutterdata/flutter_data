import 'package:flutter_data/flutter_data.dart';
import 'package:json_annotation/json_annotation.dart';

import 'adapters.dart';
import 'comment.dart';
import 'user.dart';

part 'post.g.dart';

@JsonSerializable()
@DataRepository([JSONServerAdapter])
class Post with DataModel<Post> {
  @override
  final int id;
  final String? title;
  final String? body;
  final HasMany<Comment>? comments;
  final BelongsTo<User>? user;

  Post({
    required this.id,
    required this.title,
    required this.body,
    HasMany<Comment>? comments,
    BelongsTo<User>? user,
  })  : comments = comments ?? HasMany<Comment>(),
        user = user ?? BelongsTo<User>();
}
