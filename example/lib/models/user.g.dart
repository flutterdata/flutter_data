// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) {
  return User(
    id: json['id'] as int,
    name: json['name'] as String,
    email: json['email'] as String,
  );
}

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
    };

// **************************************************************************
// RepositoryGenerator
// **************************************************************************

// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member, non_constant_identifier_names

mixin $UserLocalAdapter on LocalAdapter<User> {
  @override
  Map<String, Map<String, Object?>> relationshipsFor([User? model]) => {};

  @override
  User deserialize(map) {
    for (final key in relationshipsFor().keys) {
      map[key] = {
        '_': [map[key], !map.containsKey(key)],
      };
    }
    return _$UserFromJson(map);
  }

  @override
  Map<String, dynamic> serialize(model) => _$UserToJson(model);
}

// ignore: must_be_immutable
class $UserHiveLocalAdapter = HiveLocalAdapter<User> with $UserLocalAdapter;

class $UserRemoteAdapter = RemoteAdapter<User> with JSONServerAdapter<User>;

//

final usersLocalAdapterProvider =
    Provider<LocalAdapter<User>>((ref) => $UserHiveLocalAdapter(ref));

final usersRemoteAdapterProvider = Provider<RemoteAdapter<User>>(
    (ref) => $UserRemoteAdapter(ref.read(usersLocalAdapterProvider)));

final usersRepositoryProvider =
    Provider<Repository<User>>((ref) => Repository<User>(ref));

final _watchUser = StateNotifierProvider.autoDispose
    .family<DataStateNotifier<User?>, DataState<User?>, WatchArgs<User>>(
        (ref, args) {
  return ref.read(usersRepositoryProvider).watchOne(args.id,
      remote: args.remote,
      params: args.params,
      headers: args.headers,
      alsoWatch: args.alsoWatch);
});

AutoDisposeStateNotifierProvider<DataStateNotifier<User?>, DataState<User?>>
    watchUser(dynamic id,
        {bool? remote,
        Map<String, dynamic>? params,
        Map<String, String>? headers,
        AlsoWatch<User>? alsoWatch}) {
  return _watchUser(WatchArgs(
      id: id,
      remote: remote,
      params: params,
      headers: headers,
      alsoWatch: alsoWatch));
}

final _watchUsers = StateNotifierProvider.autoDispose.family<
    DataStateNotifier<List<User>>,
    DataState<List<User>>,
    WatchArgs<User>>((ref, args) {
  ref.maintainState = false;
  return ref.read(usersRepositoryProvider).watchAll(
      remote: args.remote,
      params: args.params,
      headers: args.headers,
      filterLocal: args.filterLocal,
      syncLocal: args.syncLocal);
});

AutoDisposeStateNotifierProvider<DataStateNotifier<List<User>>,
        DataState<List<User>>>
    watchUsers(
        {bool? remote,
        Map<String, dynamic>? params,
        Map<String, String>? headers,
        bool Function(User)? filterLocal,
        bool? syncLocal}) {
  return _watchUsers(WatchArgs(
      remote: remote,
      params: params,
      headers: headers,
      filterLocal: filterLocal,
      syncLocal: syncLocal));
}

extension UserX on User {
  /// Initializes "fresh" models (i.e. manually instantiated) to use
  /// [save], [delete] and so on.
  ///
  /// Can be obtained via `context.read`, `ref.read`, `container.read`
  User init(Reader read, {bool save = true}) {
    final repository = internalLocatorFn(usersRepositoryProvider, read);
    final updatedModel =
        repository.remoteAdapter.initializeModel(this, save: save);
    return save ? updatedModel : this;
  }
}
