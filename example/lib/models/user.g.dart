// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
    );

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
    Provider<LocalAdapter<User>>((ref) => $UserHiveLocalAdapter(ref.read));

final usersRemoteAdapterProvider = Provider<RemoteAdapter<User>>((ref) =>
    $UserRemoteAdapter(
        ref.watch(usersLocalAdapterProvider), userProvider, usersProvider));

final usersRepositoryProvider =
    Provider<Repository<User>>((ref) => Repository<User>(ref.read));

final _userProvider = StateNotifierProvider.autoDispose
    .family<DataStateNotifier<User?>, DataState<User?>, WatchArgs<User>>(
        (ref, args) {
  return ref.watch(usersRepositoryProvider).watchOneNotifier(args.id,
      remote: args.remote,
      params: args.params,
      headers: args.headers,
      alsoWatch: args.alsoWatch);
});

AutoDisposeStateNotifierProvider<DataStateNotifier<User?>, DataState<User?>>
    userProvider(dynamic id,
        {bool? remote,
        Map<String, dynamic>? params,
        Map<String, String>? headers,
        AlsoWatch<User>? alsoWatch}) {
  return _userProvider(WatchArgs(
      id: id,
      remote: remote,
      params: params,
      headers: headers,
      alsoWatch: alsoWatch));
}

final _usersProvider = StateNotifierProvider.autoDispose.family<
    DataStateNotifier<List<User>>,
    DataState<List<User>>,
    WatchArgs<User>>((ref, args) {
  return ref.watch(usersRepositoryProvider).watchAllNotifier(
      remote: args.remote,
      params: args.params,
      headers: args.headers,
      syncLocal: args.syncLocal);
});

AutoDisposeStateNotifierProvider<DataStateNotifier<List<User>>,
        DataState<List<User>>>
    usersProvider(
        {bool? remote,
        Map<String, dynamic>? params,
        Map<String, String>? headers,
        bool? syncLocal}) {
  return _usersProvider(WatchArgs(
      remote: remote, params: params, headers: headers, syncLocal: syncLocal));
}

extension UserX on User {
  /// Initializes "fresh" models (i.e. manually instantiated) to use
  /// [save], [delete] and so on.
  ///
  /// Can be obtained via `ref.read`, `container.read`
  User init(Reader read, {bool save = true}) {
    final repository = internalLocatorFn(usersRepositoryProvider, read);
    final updatedModel =
        repository.remoteAdapter.initializeModel(this, save: save);
    return save ? updatedModel : this;
  }
}
