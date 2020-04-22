// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post.dart';

// **************************************************************************
// DataGenerator
// **************************************************************************

// ignore_for_file: unused_local_variable
// ignore_for_file: always_declare_return_types
class _$PostRepository extends Repository<Post> {
  _$PostRepository(LocalAdapter<Post> adapter) : super(adapter);

  @override
  get relationshipMetadata => {
        'HasMany': {'comments': 'comments'},
        'BelongsTo': {'user': 'users'},
        'repository#comments': manager.locator<Repository<Comment>>(),
        'repository#users': manager.locator<Repository<User>>()
      };
}

class $PostRepository extends _$PostRepository
    with StandardJSONAdapter<Post>, JSONPlaceholderAdapter<Post> {
  $PostRepository(LocalAdapter<Post> adapter) : super(adapter);
}

// ignore: must_be_immutable, unused_local_variable
class $PostLocalAdapter extends LocalAdapter<Post> {
  $PostLocalAdapter(DataManager manager, {box}) : super(manager, box: box);

  @override
  deserialize(map) {
    map['comments'] = {
      '_': [map['comments'], manager]
    };
    map['user'] = {
      '_': [map['user'], manager]
    };
    return _$PostFromJson(map);
  }

  @override
  serialize(model) {
    final map = _$PostToJson(model);
    map['comments'] = model.comments?.toJson();
    map['user'] = model.user?.toJson();
    return map;
  }

  @override
  setOwnerInRelationships(owner, model) {
    model.comments?.owner = owner;
    model.user?.owner = owner;
  }

  @override
  void setInverseInModel(inverse, model) {
    if (inverse is DataId<Comment>) {
      model.comments?.inverse = inverse;
    }
    if (inverse is DataId<User>) {
      model.user?.inverse = inverse;
    }
  }
}

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
