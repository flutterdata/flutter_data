// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment.dart';

// **************************************************************************
// DataGenerator
// **************************************************************************

// ignore_for_file: unused_local_variable
// ignore_for_file: always_declare_return_types
mixin _$CommentModelAdapter on Repository<Comment> {
  @override
  Map<String, Relationship> relationshipsFor(Comment model) =>
      {'post': model?.post};

  @override
  Map<String, Repository> get relationshipRepositories =>
      {'posts': manager.locator<Repository<Post>>()};

  @override
  localDeserialize(map, {metadata}) {
    for (var key in relationshipsFor(null).keys) {
      map[key] = {
        '_': [map[key], !map.containsKey(key), manager]
      };
    }
    return _$CommentFromJson(map).._meta.addAll(metadata ?? const {});
  }

  @override
  localSerialize(model) {
    final map = _$CommentToJson(model);
    for (var e in relationshipsFor(model).entries) {
      map[e.key] = e.value?.toJson();
    }
    return map;
  }
}

extension CommentFDX on Comment {
  Map<String, dynamic> get _meta => flutterDataMetadata;
}

class $CommentRepository = Repository<Comment>
    with
        _$CommentModelAdapter,
        RemoteAdapter<Comment>,
        WatchAdapter<Comment>,
        StandardJSONAdapter<Comment>,
        JSONPlaceholderAdapter<Comment>;

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Comment _$CommentFromJson(Map<String, dynamic> json) {
  return Comment(
    id: json['id'] as int,
    body: json['body'] as String,
    approved: json['approved'] as bool,
    post: json['post'] == null
        ? null
        : BelongsTo.fromJson(json['post'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$CommentToJson(Comment instance) => <String, dynamic>{
      'id': instance.id,
      'body': instance.body,
      'approved': instance.approved,
      'post': instance.post,
    };
