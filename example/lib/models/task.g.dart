// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

// **************************************************************************
// RepositoryGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, duplicate_ignore

mixin $TaskLocalAdapter on LocalAdapter<Task> {
  static final Map<String, RelationshipMeta> kTaskRelationshipMetas = {
    'user': RelationshipMeta<User>(
      name: 'user',
      inverseName: 'tasks',
      type: 'users',
      kind: 'BelongsTo',
      instance: (_) => (_ as Task).user,
    )
  };

  @override
  Map<String, RelationshipMeta> get relationshipMetas => kTaskRelationshipMetas;

  @override
  Task deserialize(map) {
    map = transformDeserialize(map);
    return _$TaskFromJson(map);
  }

  @override
  Map<String, dynamic> serialize(model, {bool withRelationships = true}) {
    final map = _$TaskToJson(model);
    return transformSerialize(map, withRelationships: withRelationships);
  }
}

final _tasksFinders = <String, dynamic>{};

// ignore: must_be_immutable
class $TaskHiveLocalAdapter = HiveLocalAdapter<Task> with $TaskLocalAdapter;

class $TaskRemoteAdapter = RemoteAdapter<Task> with JSONServerAdapter<Task>;

final internalTasksRemoteAdapterProvider = Provider<RemoteAdapter<Task>>(
    (ref) => $TaskRemoteAdapter(
        $TaskHiveLocalAdapter(ref.read), InternalHolder(_tasksFinders)));

final tasksRepositoryProvider =
    Provider<Repository<Task>>((ref) => Repository<Task>(ref.read));

extension TaskDataRepositoryX on Repository<Task> {
  JSONServerAdapter<Task> get jSONServerAdapter =>
      remoteAdapter as JSONServerAdapter<Task>;
}

extension TaskRelationshipGraphNodeX on RelationshipGraphNode<Task> {
  RelationshipGraphNode<User> get user {
    final meta = $TaskLocalAdapter.kTaskRelationshipMetas['user']
        as RelationshipMeta<User>;
    if (this is RelationshipMeta) {
      meta.parent = this as RelationshipMeta;
    }
    return meta;
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
