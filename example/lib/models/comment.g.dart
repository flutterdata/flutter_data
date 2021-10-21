// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Comment _$CommentFromJson(Map<String, dynamic> json) => Comment(
      id: json['id'] as int,
      body: json['body'] as String?,
      approved: json['approved'] as bool? ?? false,
      post: json['post'] == null
          ? null
          : BelongsTo<Post>.fromJson(json['post'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CommentToJson(Comment instance) => <String, dynamic>{
      'id': instance.id,
      'body': instance.body,
      'approved': instance.approved,
      'post': instance.post,
    };

Sheep _$SheepFromJson(Map<String, dynamic> json) => Sheep(
      id: json['id'] as int,
      name: json['name'] as String,
    );

Map<String, dynamic> _$SheepToJson(Sheep instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
    };
