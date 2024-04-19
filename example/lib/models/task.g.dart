// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

// **************************************************************************
// RepositoryGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, duplicate_ignore

mixin _$TaskLocalAdapter on LocalAdapter<Task> {
  static final Map<String, RelationshipMeta> _kTaskRelationshipMetas = {
    'user': RelationshipMeta<User>(
      name: 'user',
      inverseName: 'tasks',
      type: 'users',
      kind: 'BelongsTo',
      instance: (_) => (_ as Task).user,
    )
  };

  @override
  Map<String, RelationshipMeta> get relationshipMetas =>
      _kTaskRelationshipMetas;

  @override
  Task deserialize(map, {String? key}) {
    map = transformDeserialize(map);
    return internalWrapStopInit(() => _$TaskFromJson(map), key: key);
  }

  @override
  Map<String, dynamic> serialize(model, {bool withRelationships = true}) {
    final map = _$TaskToJson(model);
    return transformSerialize(map, withRelationships: withRelationships);
  }
}

final _tasksFinders = <String, dynamic>{};

// ignore: must_be_immutable
class $TaskLocalAdapter = LocalAdapter<Task> with _$TaskLocalAdapter;

class $TaskRemoteAdapter = RemoteAdapter<Task> with JSONServerAdapter<Task>;

final internalTasksRemoteAdapterProvider = Provider<RemoteAdapter<Task>>(
    (ref) => $TaskRemoteAdapter(
        $TaskLocalAdapter(ref), InternalHolder(_tasksFinders)));

final tasksRepositoryProvider =
    Provider<Repository<Task>>((ref) => Repository<Task>(ref));

extension TaskDataRepositoryX on Repository<Task> {
  JSONServerAdapter<Task> get jSONServerAdapter =>
      remoteAdapter as JSONServerAdapter<Task>;
}

extension TaskRelationshipGraphNodeX on RelationshipGraphNode<Task> {
  RelationshipGraphNode<User> get user {
    final meta = _$TaskLocalAdapter._kTaskRelationshipMetas['user']
        as RelationshipMeta<User>;
    return meta.clone(
        parent: this is RelationshipMeta ? this as RelationshipMeta : null);
  }
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Task _$TaskFromJson(Map<String, dynamic> json) => Task(
      id: json['id'] as int?,
      title: json['title'] as String,
      completed: json['completed'] as bool? ?? false,
      user: json['user'] == null
          ? null
          : BelongsTo<User>.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TaskToJson(Task instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'completed': instance.completed,
      'user': instance.user,
    };
