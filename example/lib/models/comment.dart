import 'package:flutter_data/flutter_data.dart';
import 'package:json_annotation/json_annotation.dart';

import 'adapters.dart';
import 'post.dart';

part 'comment.g.dart';

// @JsonSerializable()
@DataRepository([])
class Comment with DataModel<Comment> {
  @override
  final int id;
  final String? body;
  final bool? approved;
  final BelongsTo<Post>? post;

  Comment({
    required this.id,
    required this.body,
    this.approved = false,
    BelongsTo<Post>? post,
  }) : post = post ?? BelongsTo<Post>();
}

// @JsonSerializable()
@DataRepository([], remote: false)
class Sheep with DataModel<Sheep> {
  @override
  final int id;
  final String name;

  Sheep({required this.id, required this.name});
}
