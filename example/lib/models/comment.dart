import 'package:meta/meta.dart';
import 'package:flutter_data/flutter_data.dart';
import 'package:json_annotation/json_annotation.dart';

import 'adapters.dart';
import 'post.dart';

part 'comment.g.dart';

@JsonSerializable()
@DataRepository([JSONServerAdapter])
class Comment with DataSupport<Comment> {
  @override
  final int id;
  final String body;
  bool approved = false;
  final BelongsTo<Post> post;

  Comment({
    this.id,
    @required this.body,
    this.approved,
    BelongsTo<Post> post,
  }) : post = post ?? BelongsTo<Post>();
}
