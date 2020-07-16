// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment.dart';

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

// **************************************************************************
// RepositoryGenerator
// **************************************************************************

// ignore_for_file: unused_local_variable, always_declare_return_types, non_constant_identifier_names, invalid_use_of_protected_member

mixin $CommentLocalAdapter on LocalAdapter<Comment> {
  @override
  Map<String, Map<String, Object>> relationshipsFor([Comment model]) => {
        'post': {
          'inverse': 'comments',
          'type': 'posts',
          'kind': 'BelongsTo',
          'instance': model?.post
        }
      };

  @override
  deserialize(map) {
    for (final key in relationshipsFor().keys) {
      map[key] = {
        '_': [map[key], !map.containsKey(key)],
      };
    }
    return _$CommentFromJson(map);
  }

  @override
  serialize(model) {
    final map = _$CommentToJson(model);
    for (final e in relationshipsFor(model).entries) {
      map[e.key] = (e.value['instance'] as Relationship)?.toJson();
    }
    return map;
  }
}

// ignore: must_be_immutable
class $CommentHiveLocalAdapter = HiveLocalAdapter<Comment>
    with $CommentLocalAdapter;

class $CommentRemoteAdapter = RemoteAdapter<Comment>
    with JSONServerAdapter<Comment>;

//

final commentsLocalAdapterProvider = Provider<LocalAdapter<Comment>>(
    (ref) => $CommentHiveLocalAdapter(ref.read(graphProvider)));

final commentsRemoteAdapterProvider = Provider<RemoteAdapter<Comment>>(
    (ref) => $CommentRemoteAdapter(ref.read(commentsLocalAdapterProvider)));

final commentsRepositoryProvider =
    Provider<Repository<Comment>>((_) => Repository<Comment>());

extension CommentX on Comment {
  Comment init([owner]) {
    if (owner == null && debugGlobalServiceLocatorInstance != null) {
      return debugInit(
          debugGlobalServiceLocatorInstance.get<Repository<Comment>>());
    }
    return debugInit(owner.ref.read(commentsRepositoryProvider));
  }
}

extension CommentRepositoryX on Repository<Comment> {}
