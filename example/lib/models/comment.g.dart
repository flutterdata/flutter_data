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

// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member, non_constant_identifier_names

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
  Comment deserialize(map) {
    for (final key in relationshipsFor().keys) {
      map[key] = {
        '_': [map[key], !map.containsKey(key)],
      };
    }
    return _$CommentFromJson(map);
  }

  @override
  Map<String, dynamic> serialize(model) => _$CommentToJson(model);
}

// ignore: must_be_immutable
class $CommentHiveLocalAdapter = HiveLocalAdapter<Comment>
    with $CommentLocalAdapter;

class $CommentRemoteAdapter = RemoteAdapter<Comment>
    with JSONServerAdapter<Comment>;

//

final commentLocalAdapterProvider =
    RiverpodAlias.provider<LocalAdapter<Comment>>((ref) =>
        $CommentHiveLocalAdapter(
            ref.read(hiveLocalStorageProvider), ref.read(graphProvider)));

final commentRemoteAdapterProvider =
    RiverpodAlias.provider<RemoteAdapter<Comment>>(
        (ref) => $CommentRemoteAdapter(ref.read(commentLocalAdapterProvider)));

final commentRepositoryProvider =
    RiverpodAlias.provider<Repository<Comment>>((_) => Repository<Comment>());

extension CommentX on Comment {
  /// Initializes "fresh" models (i.e. manually instantiated) to use
  /// [save], [delete] and so on.
  ///
  /// Pass:
  ///  - A `BuildContext` if using Flutter with Riverpod or Provider
  ///  - Nothing if using Flutter with GetIt
  ///  - A `ProviderStateOwner` if using pure Dart
  ///  - Its own [Repository<Comment>]
  Comment init([owner]) {
    final repository = owner is Repository<Comment>
        ? owner
        : internalLocatorFn(commentRepositoryProvider, owner);
    return repository.internalAdapter.initializeModel(this, save: true)
        as Comment;
  }
}
