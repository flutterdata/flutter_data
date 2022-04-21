// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

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

// **************************************************************************
// RepositoryGenerator
// **************************************************************************

// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member, non_constant_identifier_names

mixin $TaskLocalAdapter on LocalAdapter<Task> {
  @override
  Map<String, Map<String, Object?>> relationshipsFor([Task? model]) => {
        'user': {
          'name': 'user',
          'inverse': 'tasks',
          'type': 'users',
          'kind': 'BelongsTo',
          'instance': model?.user
        }
      };

  @override
  Task deserialize(map) {
    for (final key in relationshipsFor().keys) {
      map[key] = {
        '_': [map[key], !map.containsKey(key)],
      };
    }
    return _$TaskFromJson(map);
  }

  @override
  Map<String, dynamic> serialize(model) => _$TaskToJson(model);
}

// ignore: must_be_immutable
class $TaskHiveLocalAdapter = HiveLocalAdapter<Task> with $TaskLocalAdapter;

class $TaskRemoteAdapter = RemoteAdapter<Task> with JSONServerAdapter<Task>;

final _tasksFinders = <String, dynamic>{};

//

final tasksRemoteAdapterProvider = Provider<RemoteAdapter<Task>>((ref) =>
    $TaskRemoteAdapter($TaskHiveLocalAdapter(ref.read),
        InternalHolder(taskProvider, tasksProvider, _tasksFinders)));

final tasksRepositoryProvider =
    Provider<Repository<Task>>((ref) => Repository<Task>(ref.read));

final _taskProvider = StateNotifierProvider.autoDispose
    .family<DataStateNotifier<Task?>, DataState<Task?>, WatchArgs<Task>>(
        (ref, args) {
  final adapter = ref.watch(tasksRemoteAdapterProvider);
  final _watcherFinder = _tasksFinders[args.watcher]?.call(adapter);
  final notifier = _watcherFinder is DataWatcherOne<Task>
      ? _watcherFinder
      : adapter.watchOneNotifier;
  ref.maintainState = true;
  return notifier(args.id!,
      remote: args.remote,
      params: args.params,
      headers: args.headers,
      alsoWatch: args.alsoWatch,
      finder: args.finder,
      label: args.label);
});

AutoDisposeStateNotifierProvider<DataStateNotifier<Task?>, DataState<Task?>>
    taskProvider(
  Object? id, {
  bool? remote,
  Map<String, dynamic>? params,
  Map<String, String>? headers,
  AlsoWatch<Task>? alsoWatch,
  String? finder,
  String? watcher,
  DataRequestLabel? label,
}) {
  return _taskProvider(WatchArgs(
      id: id,
      remote: remote,
      params: params,
      headers: headers,
      alsoWatch: alsoWatch,
      finder: finder,
      watcher: watcher,
      label: label));
}

final _tasksProvider = StateNotifierProvider.autoDispose.family<
    DataStateNotifier<List<Task>?>,
    DataState<List<Task>?>,
    WatchArgs<Task>>((ref, args) {
  final adapter = ref.watch(tasksRemoteAdapterProvider);
  final _watcherFinder = _tasksFinders[args.watcher]?.call(adapter);
  final notifier = _watcherFinder is DataWatcherAll<Task>
      ? _watcherFinder
      : adapter.watchAllNotifier;
  ref.maintainState = true;
  return notifier(
      remote: args.remote,
      params: args.params,
      headers: args.headers,
      syncLocal: args.syncLocal,
      finder: args.finder,
      label: args.label);
});

AutoDisposeStateNotifierProvider<DataStateNotifier<List<Task>?>,
    DataState<List<Task>?>> tasksProvider({
  bool? remote,
  Map<String, dynamic>? params,
  Map<String, String>? headers,
  bool? syncLocal,
  String? finder,
  String? watcher,
  DataRequestLabel? label,
}) {
  return _tasksProvider(WatchArgs(
      remote: remote,
      params: params,
      headers: headers,
      syncLocal: syncLocal,
      finder: finder,
      watcher: watcher,
      label: label));
}

extension TaskDataX on Task {
  /// Initializes "fresh" models (i.e. manually instantiated) to use
  /// [save], [delete] and so on.
  ///
  /// Can be obtained via `ref.read`, `container.read`
  Task init(Reader read, {bool save = true}) {
    final repository = internalLocatorFn(tasksRepositoryProvider, read);
    final updatedModel =
        repository.remoteAdapter.initializeModel(this, save: save);
    return save ? updatedModel : this;
  }
}

extension TaskDataRepositoryX on Repository<Task> {
  JSONServerAdapter<Task> get jSONServerAdapter =>
      remoteAdapter as JSONServerAdapter<Task>;
}
