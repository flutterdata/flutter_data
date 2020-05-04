// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment.dart';

// **************************************************************************
// DataGenerator
// **************************************************************************

// ignore_for_file: unused_local_variable
// ignore_for_file: always_declare_return_types
class _$CommentRepository extends Repository<Comment> {
  _$CommentRepository(LocalAdapter<Comment> adapter,
      {bool remote, bool verbose})
      : super(adapter, remote: remote, verbose: verbose);

  @override
  get relationshipMetadata => {
        'HasMany': {},
        'BelongsTo': {'post': 'posts'}
      };

  @override
  Repository repositoryFor(String type) {
    return <String, Repository>{
      'posts': manager.locator<Repository<Post>>()
    }[type];
  }
}

class $CommentRepository extends _$CommentRepository
    with StandardJSONAdapter<Comment>, JSONPlaceholderAdapter<Comment> {
  $CommentRepository(LocalAdapter<Comment> adapter, {bool remote, bool verbose})
      : super(adapter, remote: remote, verbose: verbose);
}

// ignore: must_be_immutable, unused_local_variable
class $CommentLocalAdapter extends LocalAdapter<Comment> {
  $CommentLocalAdapter(DataManager manager, {List<int> encryptionKey, box})
      : super(manager, encryptionKey: encryptionKey, box: box);

  @override
  deserialize(map) {
    map['post'] = {
      '_': [map['post'], manager]
    };
    return _$CommentFromJson(map);
  }

  @override
  serialize(model) {
    final map = _$CommentToJson(model);
    map['post'] = model.post?.toJson();
    return map;
  }

  @override
  setOwnerInRelationships(owner, model) {
    model.post?.owner = owner;
  }

  @override
  void setInverseInModel(inverse, model) {
    if (inverse is DataId<Post>) {
      model.post?.inverse = inverse;
    }
  }
}

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
