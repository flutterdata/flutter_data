<!-- markdownlint-disable MD033 MD041 -->
<p align="center" style="margin-bottom: 0px;">
  <img src="https://avatars2.githubusercontent.com/u/61839689?s=200&v=4" width="85px">
</p>

<h1 align="center" style="margin-top: 0px; font-size: 4em;">Flutter Data</h1>

[![tests](https://img.shields.io/github/workflow/status/flutterdata/flutter_data/test/master?label=tests&labelColor=333940&logo=github)](https://github.com/flutterdata/flutter_data/actions) [![codecov](https://codecov.io/gh/flutterdata/flutter_data/branch/master/graph/badge.svg)](https://codecov.io/gh/flutterdata/flutter_data) [![pub.dev](https://img.shields.io/pub/v/flutter_data?label=pub.dev&labelColor=333940&logo=dart)](https://pub.dev/packages/flutter_data) [![license](https://img.shields.io/github/license/flutterdata/flutter_data?color=%23007A88&labelColor=333940&logo=mit)](https://github.com/flutterdata/flutter_data/blob/master/LICENSE)

## Persistent reactive models in Flutter with zero boilerplate

Flutter Data is an offline-first persistence framework that gives you a configurable REST client and powerful model relationships.

Heavily inspired by [Ember Data](https://github.com/emberjs/data) and [ActiveRecord](https://guides.rubyonrails.org/active_record_basics.html)

---

## Features

- **Repositories for all models** 🚀
  - CRUD and custom remote endpoints
  - [StateNotifier](https://pub.dev/packages/state_notifier) watcher APIs
- **Built for offline-first** 🔌
  - [Hive](https://docs.hivedb.dev/)-based local storage at its core
  - Failure handling & retry API
- **Intuitive APIs, effortless setup** 💙
  - Truly configurable and composable via Dart mixins and codegen
  - Built-in [Riverpod](https://riverpod.dev/) providers for all models
- **Exceptional relationship support** ⚡️
  - Automatically synchronized, fully traversable relationship graph
  - Reactive relationships

**Check out the [Documentation](https://flutterdata.dev) or the [Tutorial](https://flutterdata.dev/tutorial) 📚 where we build a TO-DO app from the ground up in record time.**

## Set up

See the [quickstart guide](https://flutterdata.dev/docs/quickstart/) for setup and boot configuration.

Prefer an example? Here's the Flutter Data [sample setup app](https://github.com/flutterdata/flutter_data_setup_app) with support for Riverpod, Provider and get_it.

## 👩🏾‍💻 Usage

For a given `User` model annotated with `@DataRepository`:

```dart
@JsonSerializable()
@DataRepository([MyJSONServerAdapter])
class User with DataModel<User> {
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

After a code-gen build, Flutter Data will generate a `Repository<User>`
and utilities such as `userProvider` and `ref.users.watchOne` (Riverpod only):

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

`ref.users.watchOne(1)` is a handy shortcut to the `userProvider` which provides `ref.watch(usersRepositoryProvider).watchOneNotifier(1)`.

Let's see how to update the user:

```dart
TextButton(
  onPressed: () => ref.users.save(User(id: 1, name: 'Updated')),
  child: Text('Update'),
),
```

`ref.users.watchOne(1)` will make an HTTP request (to `https://my-json-server.typicode.com/flutterdata/demo/users/1` in this case), parse the incoming JSON and listen for any further changes to the `User` – whether those are local or remote!

`state` is of type `DataState` which has loading, error and data substates.

In addition to the reactivity, `DataModel`s get extensions and automatic relationships, ActiveRecord-style, so the above becomes:

```dart
GestureDetector(
  onTap: () =>
      User(id: 1, name: 'Updated').init(ref.read).save(),
  child: Text('Update')
),
```

Some other examples:

```dart
final todo = await Todo(title: 'Finish docs').init(ref.read).save();
// or its equivalent:
final todo = await ref.todos.save(Todo(title: 'Finish docs'));
// POST https://my-json-server.typicode.com/flutterdata/demo/todos/
print(todo.id); // 201

final user = await repository.findOne(1, params: { '_embed': 'todos' });
// (remember repository can be accessed via ref.users)
// GET https://my-json-server.typicode.com/flutterdata/demo/users/1?_embed=todos
print(user.todos.length); // 20

await user.todos.last.delete();
```

**Explore the [Documentation](https://flutterdata.dev/docs/).**

Fully functional app built with Flutter Data? See the code for the finished **[Flutter Data Tasks App](https://github.com/flutterdata/tutorial)**.

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
      <td class="px-4 py-2 text-sm">And pure Dart, too.</td>
    </tr>
    <tr class="bg-yellow-50">
      <td class="font-bold px-4 py-2"><strong>Flutter Web</strong></td>
      <td class="px-4 py-2">✅</td>
      <td class="px-4 py-2 text-sm">Supported!</td>
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
      <td class="font-bold px-4 py-2"><strong>Provider</strong></td>
      <td class="px-4 py-2">✅</td>
      <td class="px-4 py-2 text-sm">Supported with minimal extra code</td>
    </tr>
    <tr class="bg-yellow-50">
      <td class="font-bold px-4 py-2"><strong>get_it</strong></td>
      <td class="px-4 py-2">✅</td>
      <td class="px-4 py-2 text-sm">Supported with minimal extra code</td>
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
    <tr>
      <td class="font-bold px-4 py-2"><strong>Freezed</strong></td>
      <td class="px-4 py-2">✅</td>
      <td class="px-4 py-2 text-sm">Supported!</td>
    </tr>
  </tbody>
</table>

## 📲 Apps using Flutter Data

![logos](https://user-images.githubusercontent.com/66403/115444364-79053f80-a1e2-11eb-9498-ee86718a4be5.png)

## ➕ Questions and collaborating

Please use Github to ask questions, open issues and send PRs. Thanks!

On Twitter: [@flutterdata](https://twitter.com/flutterdata)

Tests can be run with: `pub run test`

## 📝 License

See [LICENSE](https://github.com/flutterdata/flutter_data/blob/master/LICENSE).
