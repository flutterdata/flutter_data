// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

// **************************************************************************
// AdapterGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, duplicate_ignore

mixin _$TaskAdapter on Adapter<Task> {
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

class $TaskAdapter = Adapter<Task> with _$TaskAdapter, JSONServerAdapter<Task>;

final tasksAdapterProvider = Provider<Adapter<Task>>(
    (ref) => $TaskAdapter(ref, InternalHolder(_tasksFinders)));

extension TaskAdapterX on Adapter<Task> {
  JSONServerAdapter<Task> get jSONServerAdapter =>
      this as JSONServerAdapter<Task>;
}

extension TaskRelationshipGraphNodeX on RelationshipGraphNode<Task> {
  RelationshipGraphNode<User> get user {
    final meta =
        _$TaskAdapter._kTaskRelationshipMetas['user'] as RelationshipMeta<User>;
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
