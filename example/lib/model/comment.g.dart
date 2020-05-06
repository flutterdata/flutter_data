// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment.dart';

// **************************************************************************
// DataGenerator
// **************************************************************************

// ignore_for_file: unused_local_variable
// ignore_for_file: always_declare_return_types
mixin _$CommentModelAdapter on Repository<Comment> {
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

  @override
  deserialize(map, {key, initialize = true}) {
    map['post'] = {
      '_': [map['post'], manager]
    };
    return _$CommentFromJson(map as Map<String, dynamic>);
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

class $CommentRepository = Repository<Comment>
    with
        _$CommentModelAdapter,
        RemoteAdapter<Comment>,
        ReactiveAdapter<Comment>,
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
