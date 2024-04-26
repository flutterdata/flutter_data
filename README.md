<!-- markdownlint-disable MD033 MD041 -->
<p align="center" style="margin-bottom: 0px;">
  <img src="https://avatars2.githubusercontent.com/u/61839689?s=200&v=4" width="85px">
</p>

<h1 align="center" style="margin-top: 0px; font-size: 4em;">Flutter Data</h1>

[![tests](https://img.shields.io/github/actions/workflow/status/flutterdata/flutter_data/test.yml?branch=master)](https://github.com/flutterdata/flutter_data/actions) [![codecov](https://codecov.io/gh/flutterdata/flutter_data/branch/master/graph/badge.svg)](https://codecov.io/gh/flutterdata/flutter_data) [![pub.dev](https://img.shields.io/pub/v/flutter_data?label=pub.dev&labelColor=333940&logo=dart)](https://pub.dev/packages/flutter_data) [![license](https://img.shields.io/github/license/flutterdata/flutter_data?color=%23007A88&labelColor=333940&logo=mit)](https://github.com/flutterdata/flutter_data/blob/master/LICENSE)

## Persistent reactive models in Flutter with zero boilerplate

Flutter Data is an offline-first data framework with a customizable REST client and powerful model relationships, built on Riverpod.

<small>Inspired by [Ember Data](https://github.com/emberjs/data) and [ActiveRecord](https://guides.rubyonrails.org/active_record_basics.html).</small>

## Features

- **Adapters for all models** 🚀
  - Default CRUD and custom remote endpoints
  - [StateNotifier](https://pub.dev/packages/state_notifier) watcher APIs
- **Built for offline-first** 🔌
  - [SQLite3](https://pub.dev/packages/sqlite3)-based local storage at its core, with adapters for many other engines: Objectbox, Isar, etc (coming soon)
  - Failure handling & retry API
- **Intuitive APIs, effortless setup** 💙
  - Truly configurable and composable via Dart mixins and codegen
  - Built-in [Riverpod](https://riverpod.dev/) providers for all models
- **Exceptional relationship support** ⚡️
  - Automatically synchronized, fully traversable relationship graph
  - Reactive relationships

## 👩🏾‍💻 Quick introduction

In Flutter Data, every model gets its default adapter. These adapters can be extended by mixing in custom adapters.

Annotate a model with `@DataAdapter` and pass a custom adapter:

```dart
@JsonSerializable()
@DataAdapter([MyJSONServerAdapter])
class User extends DataModel<User> {
  @override
  final int? id; // ID can be of any type
  final String name;
  User({this.id, required this.name});
  // `User.fromJson` and `toJson` optional
}

mixin MyJSONServerAdapter on RemoteAdapter<User> {
  @override
  String get baseUrl => "https://my-json-server.typicode.com/flutterdata/demo/";
}
```

After code-gen, Flutter Data will generate the resulting `Adapter<User>` which is accessible via Riverpod's `ref.users` or `container.users`.

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final state = ref.users.watchOne(1);
  if (state.isLoading) {
    return Center(child: const CircularProgressIndicator());
  }
  final user = state.model;
  return Text(user.name);
}
```

To update the user:

```dart
TextButton(
  onPressed: () => ref.users.save(User(id: 1, name: 'Updated')),
  child: Text('Update'),
),
```

`ref.users.watchOne(1)` will make a background HTTP request (to `https://my-json-server.typicode.com/flutterdata/demo/users/1` in this case), deserialize data and listen for any further local changes to the user.

`state` is of type `DataState` which has loading, error and data substates.

In addition to the reactivity, models have ActiveRecord-style extension methods so the above becomes:

```dart
GestureDetector(
  onTap: () => User(id: 1, name: 'Updated').save(),
  child: Text('Update')
),
```

## Compatibility

Fully compatible with the tools we know and love:

<table class="table-fixed">
  <thead>
    <tr>
      <th class="w-4/12"></th>
      <th class="w-1/12"></th>
      <th class="w-7/12"></th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td class="font-bold px-4 py-2"><strong>Flutter</strong></td>
      <td class="px-4 py-2">✅</td>
      <td class="px-4 py-2 text-sm">Or plain Dart. It does not require Flutter.</td>
    </tr>
    <tr>
      <td class="font-bold px-4 py-2"><strong>json_serializable</strong></td>
      <td class="px-4 py-2">✅</td>
      <td class="px-4 py-2 text-sm">Fully supported (but not required)
      </td>
    </tr>
    <tr class="bg-yellow-50">
      <td class="font-bold px-4 py-2"><strong>Riverpod</strong></td>
      <td class="px-4 py-2">✅</td>
      <td class="px-4 py-2 text-sm">Supported &amp; automatically wired up</td>
    </tr>
    <tr>
      <td class="font-bold px-4 py-2"><strong>Classic JSON REST API</strong></td>
      <td class="px-4 py-2">✅</td>
      <td class="px-4 py-2 text-sm">Built-in support!</td>
    </tr>
    <tr class="bg-yellow-50">
      <td class="font-bold px-4 py-2"><strong>JSON:API</strong></td>
      <td class="px-4 py-2">✅</td>
      <td class="px-4 py-2 text-sm">Supported via <a href="https://pub.dev/packages/flutter_data_json_api_adapter">external adapter</a></td>
    </tr>
    <tr class="bg-yellow-50">
      <td class="font-bold px-4 py-2"><strong>Firebase, Supabase, GraphQL</strong></td>
      <td class="px-4 py-2">✅</td>
      <td class="px-4 py-2 text-sm">Can be fully supported by writing custom adapters</a></td>
    </tr>
    <tr>
      <td class="font-bold px-4 py-2"><strong>Freezed</strong></td>
      <td class="px-4 py-2">✅</td>
      <td class="px-4 py-2 text-sm">Supported!</td>
    </tr>
    <tr class="bg-yellow-50">
      <td class="font-bold px-4 py-2"><strong>Flutter Web</strong></td>
      <td class="px-4 py-2">✅</td>
      <td class="px-4 py-2 text-sm">TBD</td>
    </tr>
  </tbody>
</table>

## 📲 Apps using Flutter Data in production

![logos](https://user-images.githubusercontent.com/66403/115444364-79053f80-a1e2-11eb-9498-ee86718a4be5.png)

 - [Drexbible](https://snapcraft.io/drexbible)

## 🚨 BREAKING CHANGES IN 2.0

 - All methods are now directly on `Adapter`, there is no `Repository`, `RemoteAdapter` or `LocalAdapter`. Any method you are looking for is probably on `Adapter`, for example, `findAll` from `LocalAdapter` is now called `findAllLocal`
 - For initialization we no longer call the `configure...` method on the Riverpod overrides, we just do `localStorageProvider.overrideWithValue` and pass a `LocalStorage` instance; the actual initialization is done via `initializeFlutterData` which needs an adapter map. An `adapterProvidersMap` is conveniently code-generated and available on `main.data.dart`

## 📚 API

### Adapters

WIP. Method names should be self explanatory. All of these methods have a reasonable default implementation.

#### Public API

```dart
// local storage

List<T> findAllLocal();

List<T> findManyLocal(Iterable<String> keys);

List<T> deserializeFromResult(ResultSet result);

T? findOneLocal(String? key);

T? findOneLocalById(Object id);

bool exists(String key);

T saveLocal(T model, {bool notify = true});

Future<List<String>?> saveManyLocal(Iterable<DataModelMixin> models,
      {bool notify = true, bool async = true});

void deleteLocal(T model, {bool notify = true});

void deleteLocalById(Object id, {bool notify = true});

void deleteLocalByKeys(Iterable<String> keys, {bool notify = true});

Future<void> clearLocal({bool notify = true});

int get countLocal;

Set<String> get keys;

// remote

Future<List<T>> findAll({
    bool remote = true,
    bool background = false,
    Map<String, dynamic>? params,
    Map<String, String>? headers,
    bool syncLocal = false,
    OnSuccessAll<T>? onSuccess,
    OnErrorAll<T>? onError,
    DataRequestLabel? label,
  });

Future<T?> findOne(
    Object id, {
    bool remote = true,
    bool background = false,
    Map<String, dynamic>? params,
    Map<String, String>? headers,
    OnSuccessOne<T>? onSuccess,
    OnErrorOne<T>? onError,
    DataRequestLabel? label,
  });

Future<T> save(
    T model, {
    bool remote = true,
    Map<String, dynamic>? params,
    Map<String, String>? headers,
    OnSuccessOne<T>? onSuccess,
    OnErrorOne<T>? onError,
    DataRequestLabel? label,
  });

Future<T?> delete(
    Object model, {
    bool remote = true,
    Map<String, dynamic>? params,
    Map<String, String>? headers,
    OnSuccessOne<T>? onSuccess,
    OnErrorOne<T>? onError,
    DataRequestLabel? label,
  });

Set<OfflineOperation<T>> get offlineOperations;

// serialization

Map<String, dynamic> serializeLocal(T model, {bool withRelationships = true});

T deserializeLocal(Map<String, dynamic> map, {String? key});

Future<Map<String, dynamic>> serialize(T model,
      {bool withRelationships = true});

Future<DeserializedData<T>> deserialize(Object? data,
      {String? key, bool async = true});

Future<DeserializedData<T>> deserializeAndSave(Object? data,
      {String? key, bool notify = true, bool ignoreReturn = false});

// watchers

DataState<List<T>> watchAll({
    bool remote = false,
    Map<String, dynamic>? params,
    Map<String, String>? headers,
    bool syncLocal = false,
    String? finder,
    DataRequestLabel? label,
  });

DataState<T?> watchOne(
    Object model, {
    bool remote = false,
    Map<String, dynamic>? params,
    Map<String, String>? headers,
    AlsoWatch<T>? alsoWatch,
    String? finder,
    DataRequestLabel? label,
  });

DataStateNotifier<List<T>> watchAllNotifier(
      {bool remote = false,
      Map<String, dynamic>? params,
      Map<String, String>? headers,
      bool syncLocal = false,
      String? finder,
      DataRequestLabel? label});

DataStateNotifier<T?> watchOneNotifier(Object model,
      {bool remote = false,
      Map<String, dynamic>? params,
      Map<String, String>? headers,
      AlsoWatch<T>? alsoWatch,
      String? finder,
      DataRequestLabel? label});

final coreNotifierThrottleDurationProvider;
```

#### Protected API

```dart
// adapter

Future<void> onInitialized();

Future<Adapter<T>> initialize({required Ref ref});

void dispose();

Future<R> runInIsolate<R>(FutureOr<R> fn(Adapter adapter));

void log(DataRequestLabel label, String message, {int logLevel = 1});

void onModelInitialized(T model) {};

// remote

String get baseUrl;

FutureOr<Map<String, dynamic>> get defaultParams;

FutureOr<Map<String, String>> get defaultHeaders;

String urlForFindAll(Map<String, dynamic> params);

DataRequestMethod methodForFindAll(Map<String, dynamic> params);

String urlForFindOne(id, Map<String, dynamic> params);

DataRequestMethod methodForFindOne(id, Map<String, dynamic> params);

String urlForSave(id, Map<String, dynamic> params);

DataRequestMethod methodForSave(id, Map<String, dynamic> params);

String urlForDelete(id, Map<String, dynamic> params);

DataRequestMethod methodForDelete(id, Map<String, dynamic> params);

bool shouldLoadRemoteAll(
    bool remote,
    Map<String, dynamic> params,
    Map<String, String> headers,
  );

bool shouldLoadRemoteOne(
    Object? id,
    bool remote,
    Map<String, dynamic> params,
    Map<String, String> headers,
  );

bool isOfflineError(Object? error);

http.Client get httpClient;

Future<R?> sendRequest<R>(
    final Uri uri, {
    DataRequestMethod method = DataRequestMethod.GET,
    Map<String, String>? headers,
    Object? body,
    _OnSuccessGeneric<R>? onSuccess,
    _OnErrorGeneric<R>? onError,
    bool omitDefaultParams = false,
    bool returnBytes = false,
    DataRequestLabel? label,
    bool closeClientAfterRequest = true,
  });

FutureOr<R?> onSuccess<R>(
    DataResponse response, DataRequestLabel label);

FutureOr<R?> onError<R>(
    DataException e,
    DataRequestLabel? label,
  );

// serialization

Map<String, dynamic> transformSerialize(Map<String, dynamic> map,
      {bool withRelationships = true});

Map<String, dynamic> transformDeserialize(Map<String, dynamic> map);
```

## ➕ Questions and collaborating

Please use Github to ask questions, open issues and send PRs. Thanks!

Tests can be run with: `dart test`

## 📝 License

See [LICENSE](https://github.com/flutterdata/flutter_data/blob/master/LICENSE).
