// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post.dart';

// **************************************************************************
// DataGenerator
// **************************************************************************

// ignore_for_file: unused_local_variable, always_declare_return_types, non_constant_identifier_names
mixin _$PostModelAdapter on Repository<Post> {
  @override
  Map<String, Map<String, Object>> relationshipsFor([Post model]) => {
        'comments': {
          'type': 'comments',
          'kind': 'HasMany',
          'instance': model?.comments
        },
        'user': {'type': 'users', 'kind': 'BelongsTo', 'instance': model?.user}
      };

  @override
  Map<String, Repository> get relatedRepositories => {
        'comments': manager.locator<Repository<Comment>>(),
        'users': manager.locator<Repository<User>>()
      };

  @override
  localDeserialize(map) {
    for (final key in relationshipsFor().keys) {
      map[key] = {
        '_': [map[key], !map.containsKey(key), manager]
      };
    }
    return _$PostFromJson(map);
  }

  @override
  localSerialize(model) {
    final map = _$PostToJson(model);
    for (final e in relationshipsFor(model).entries) {
      map[e.key] = (e.value['instance'] as Relationship)?.toJson();
    }
    return map;
  }
}

class $PostRepository = Repository<Post>
    with
        _$PostModelAdapter,
        RemoteAdapter<Post>,
        WatchAdapter<Post>,
        JSONServerAdapter<Post>;

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Post _$PostFromJson(Map<String, dynamic> json) {
  return Post(
    id: json['id'] as int,
    title: json['title'] as String,
    body: json['body'] as String,
    comments: json['comments'] == null
        ? null
        : HasMany.fromJson(json['comments'] as Map<String, dynamic>),
    user: json['user'] == null
        ? null
        : BelongsTo.fromJson(json['user'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$PostToJson(Post instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'body': instance.body,
      'comments': instance.comments,
      'user': instance.user,
    };
