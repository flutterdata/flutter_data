<p align="center" style="margin-bottom: 0px;">
  <img src="https://avatars2.githubusercontent.com/u/61839689?s=200&v=4" width="85px">
</p>

<h1 align="center" style="margin-top: 0px; font-size: 4em;">Flutter Data</h1>

[![tests](https://img.shields.io/github/workflow/status/flutterdata/flutter_data/test/master?label=tests&labelColor=333940&logo=github)](https://github.com/flutterdata/flutter_data/actions) [![pub.dev](https://img.shields.io/pub/v/flutter_data?label=pub.dev&labelColor=333940&logo=dart)](https://pub.dev/packages/flutter_data) [![license](https://img.shields.io/github/license/flutterdata/flutter_data?color=%23007A88&labelColor=333940&logo=mit)](https://github.com/flutterdata/flutter_data/blob/master/LICENSE)

(➡️ jump to toc)

You're working on a Flutter app heavily using http/Dio, Hive, Chopper or Firebase, json_serializable, Provider and probably other tools. Making everything work together smoothly feels... painful 😫.

What if you could remove all the headaches and have things **just work** in a very clean way?

Here's how:

### 🎯 Mini TO-DO list example

Let's display [JSON Placeholder](https://jsonplaceholder.typicode.com/) "User 1"'s list of todos:

```dart
FutureBuilder<List<Todo>>(
  future: context.read<Repository<Todo>>().findAll(params: {'userId': '1'});
  builder: (context, snapshot) {
    return ListView.builder(
      itemBuilder: (context, i) {
        final todo = snapshot.data[i];
        return Text('TO-DO: ${todo.title}'),
      },
    );
  }
}
```

We just:

 - Got hold of a repository for `Todo` via Provider
 - Fetched a todo list for user id=1 (URL: `https://jsonplaceholder.typicode.com/todos?userId=1`)
 - Deserialized JSON data into a list of `Todo` models
 - Displayed the list in a `FutureBuilder`

How was that possible?

1. We annotate two models `User` and `Todo` with `@DataRepository`
1. We make our models `extend DataSupport` (a mixin is also available)
1. We run codegen: `flutter packages pub run build_runner build`

```dart
@JsonSerializable()
@DataRepository([StandardJSONAdapter, JSONPlaceholderAdapter])
class User extends DataSupport<User> {
  @override
  final int id;
  final String name;
  final HasMany<Todo> todos;

  User({ //... });
}

@JsonSerializable()
@DataRepository([StandardJSONAdapter, JSONPlaceholderAdapter])
class Todo extends DataSupport<Todo> {
  @override
  final int id;
  final String title;
  final bool completed;
  final BelongsTo<User> user;

  Todo({ //... });
}
```

We now have a `UserRepository` and a `TodoRepository` that we can retrieve with Provider:

```dart
final userRepository = context.read<Repository<User>>();
final todoRepository = context.read<Repository<Todo>>();
```

(We'll later see how we wired up Provider in literally one line of code.)

So where is the base URL `https://jsonplaceholder.typicode.com/` configured? 🤔

Answer: In a custom _adapter_!

```dart
mixin JSONPlaceholderAdapter<T extends DataSupport<T>> on StandardJSONAdapter<T> {
  @override
  String get baseUrl => 'https://jsonplaceholder.typicode.com/';

  @override
  String get identifierSuffix => 'Id';
}
```

Adapters (which are Dart mixins) are used to configure anything and everything! We simply have to add them as parameters to our annotation.

```dart
@DataRepository([StandardJSONAdapter, JSONPlaceholderAdapter]);
```

Our own `JSONPlaceholderAdapter` is _customizing_ the `StandardJSONAdapter` which ships with Flutter Data (notice `on StandardJSONAdapter<T>`). Order matters!

Want to see the real working app: https://github.com/flutterdata/flutter_data_todos

### Saving a new TO-DO!

Let's save a new TO-DO:

```dart
FloatingActionButton(
  onPressed: () {
    Todo(title: "Task number ${Random().nextInt(9999)}").save();
  },
```

Done!

(We used a random title so we don't have to mess with inputs right now!)

This triggered a `POST` HTTP request in the background to `https://jsonplaceholder.typicode.com/todos`

(snap)

Why can't we see it?

### ⚡️ Reactive TO-DO list

We can't see it because we used a `FutureBuilder` which fetches the list just once.

Let's make it reactive!

```dart
DataStateBuilder<List<Todo>>(
  notifier: context.read<Repository<Todo>>().watchAll(params: {'userId': '1'});
  builder: (context, state, _) {
    return ListView.builder(
      itemBuilder: (context, i) {
        if (state.isLoading) {
          return CircularProgressIndicator();
        }
        return Text('TO-DO: ${state.model.title}'),
      },
    );
  }
}
```

Now using `watchAll()`, creating a new TO-DO _will_ show up in the list!

Under the hood, we are using the `data_state` package which essentially is a [`StateNotifier`](https://pub.dev/packages/state_notifier), i.e. a "Flutter-free ValueNotifier".

Prefer a Stream API? No problem:

```dart
StreamBuilder<List<Todo>>(
  notifier: context.read<Repository<Todo>>().watchAll(params: {'userId': '1'}).stream;
  builder: (context, snapshot) {
    return ListView.builder(
      itemBuilder: (context, i) {
        final todo = snapshot.data[i];
        return Text('TO-DO: ${todo.title}'),
      },
    );
  }
}
```

### 🎎 Relationships

Let's now slightly rethink our query. Instead of "fetching all TO-DOs for user 1" we are going to "get user 1 with all their TO-DOs".

```dart
DataStateBuilder<User>(
  notifier: context.read<Repository<User>>().watchOne('1', params: {'_embed': 'todos'});
  builder: (context, state, _) {
    final user = state.model;
    return ListView.builder(
      itemBuilder: (context, i) {
        return Text('TO-DO: ${user.todos[i]} is for ${user.name}'),
      },
    );
  }
}
```

(snap)

Relationships between models are automagically wired up!

Everything is automatically saved to local storage (Hive database). The default behavior is to get models from local storage first and then fetch models from the remote server in the background.

This strategy can easily be changed by overriding methods in a custom adapter.

## ☯️ Philosophy

**"Simple should be easy, complex should be possible"**

In a nutshell, Flutter Data is:

 - reactive architecture ⚡️
 - transparent API access and serialization 📩
 - offline-first 🔌
 - magic relationship support 🎎
 - extremely configurable and composable 🧱
 - with minimal boilerplate!

Fully compatible with the tools we know and love:

|                   | Compatible | Optional |
|-------------------|------------|----------|
| Flutter           |     ✅     |   Yes    |
| json_serializable |     ✅     |   No     |
| Firebase          |     ✅(*)  |   Yes    |
| Firebase Auth     |     ✅(*)  |   Yes    |
| REST API + JSON   |     ✅     |   Yes    |
| JSON:API          |     ✅     |   Yes    |
| Provider / Hooks  |     ✅     |   Yes    |
| Streams / BLoC    |     ✅     |   Yes    |
| Freezed           |     ✅     |   Yes    |
| state_notifier    |     ✅     |   Yes    |
| Hive              |     ✅     |   No     |
| Pure Dart         |     ✅     |   No     |

(*) **Firebase and other adapters are coming soon!**

## 👩🏾‍💻 API overview

(toc here)

### repo public api, extending with adapters; official docs soon

```dart
final repository = context.read<Repository<User>>();

// returns a list of all users from the remote API
List<User> users = await repository.findAll();

// returns just one user by ID
User user = await repository.findOne('34');

// subscribe to updates (see the data_state package)
DataStateNotifier<User> usersNotifier = repository.watchAll();

// alternatively can get a stream version of it (RxDart ValueStream)
ValueStream<User> usersStream = repository.watchAll().stream;

// do you need to get updates for one model?
// (yes, even updates in the local store)

Widget build(BuildContext context) {
  return StateNotifierBuilder<DataState<User>>(
    stateNotifier: user.watch(),
    builder: (context, state, _) {
      if (state.hasModel) {
        final user = state.model;
```

   - For example, Wordpress, Github or even a JWT auth adapters are easy to make.
   - There are a million ways to extend capabilities through adapters. We'll get to that later.
 
### datasupport<t>, mixin, fromjson required, relationships; is optional can just use repo

#### Saving and deleting a model

```dart
final user = await User(name: 'Frank Treacy').save();

// which is syntax sugar for
final user = await repository.save(User(name: 'Frank Treacy'));

// only save locally
await User(name: 'Frank Treacy').save(remote: false);

// delete user
await user.delete();
```

#### Using relationships

Flutter Data has a powerful relationship mapping system.

Provided the API responds correctly with relationship data,
we can expect the following to work:

```dart
// recall that User has a HasMany<Todo> attribute
User user = await repository.findOne('Frank');

Todo todo = user.todos.first;

print(todo.title); // write Flutter Data docs

print(todo.user.value.name); // Frank

// or

final family = Family(
      surname: 'Kamchatka',
      house: BelongsTo(House(address: "Sakharova Prospekt, 19"))
    );
print(family.house.value.families.first.surname);  // Kamchatka
```

## 🔧 Configuration

Flutter Data ships with a `dataProviders` method that will configure all the necessary Providers.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_data/flutter_data.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:todo_app/main.data.dart';

void main() {
  runApp(MultiProvider(
    providers: [
      ...dataProviders(getApplicationDocumentsDirectory),
      // your providers here
    ],
    child: TodoApp(),
  ));
}

class TodoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (context.watch<DataManager>() == null) {
      return Spinner();
    }
    // all Flutter Data providers are ready at this point
    return MaterialApp(
// ...
```

Flutter Data auto-generated the `main.data.dart` library so everything is ready to for use.

#### No Provider? No problem!

```dart
// main.dart

import 'package:flutter/material.dart';
import 'package:flutter_data/flutter_data.dart';
import 'package:path_provider/path_provider.dart';
import 'package:todo_app/main.data.dart';

void main() {
  runApp(Center(child: const CircularProgressIndicator()));

  final baseDir = await getApplicationDocumentsDirectory();
  final manager = await FlutterData.init(baseDir);
  Locator locator = manager.locator;

  runApp(MaterialApp(
    // ...
    final repository = locator<Repository<User>>();
    // ...
  ));
}
```

`Locator` is a typedef suggested by [Remi Rousselet](https://twitter.com/remi_rousselet):

```dart
typedef Locator = T Function<T>();
```

Any conforming type can be used:

 - the bundled `locator` shown above
 - a `get_it` locator
 - `context.read` from the Provider package

#### Don't even use Flutter?

```dart
void main() async {
  Directory _dir;

  try {
    _dir = await Directory('/tmp/myapp').create();
    final manager = await FlutterData.init(_dir);
    Locator locator = manager.locator;
    
    final repository = locator<Repository<User>>();
    
    // ...

  } finally {
    await _dir.delete(recursive: true);
  }
}
```

## 👩‍🍳 Cookbook

Let's say we need extra headers in our requests:

```dart
mixin BaseAdapter<T extends DataSupportMixin<T>> on Repository<T> {
  final _localStorageService = manager.locator<LocalStorageService>();

  @override
  get baseUrl => "http://my.remote.url:8080/";

  @override
  get headers {
    final token = _localStorageService.getToken();
    return super.headers..addAll({'Authorization': token});
  }
}
```

All `Repository` public methods like `findAll`, `save`, `serialize`, `deserialize`, ... are available.

Let's make the stupid adapter, that appends `zzz` to any ID:

```dart
mixin StupidAdapter<T extends DataSupportMixin<T>> on Repository<T> {
  @override
  Future<T> findOne(String id,
      {bool remote = true,
      Map<String, String> params,
      Map<String, String> headers}) {
        return super.findOne('${id}zzz', remote: remote, params: params, headers: headers);
      }
}
```

Or how about a –much more useful– JWT auth service:

```dart
mixin AuthAdapter<DataSupportMixin> on Repository<User> {
  Future<String> login(String email, String password) async {
    final repository = this as Repository<User>;

    final response = await repository.withHttpClient(
      (client) => client.post(
        '$baseUrl/token',
        body: _serializeCredentials(user, password),
        headers: headers,
      ),
    );

    final map = json.decode(response.body);
    return map['token'] as String;
  }
}
```

Now this adapter can be configured and exposed *just* on the `User` model:

```dart
@JsonSerializable()
@DataRepository([StandardJSONAdapter, BaseAdapter, AuthAdapter])
class User extends DataSupport<User> {
  // ...

  loginWithPassword(String password) {
    return (repository as AuthAdapter).login(email, password);
  }
}
```

And more, like:

 - replace the HTTP client
 - provide a completely new URL design


## FAQ

#### Does Flutter Data depend on Flutter?

No! Despite its name this library does not depend on Flutter at all.

Here is a pure Dart example. Also see tests.

#### Can i use it with Provider?

Yes! Remember to use `context.read<Repository<T>>()` (or `Provider.of<Repository<T>>(listen: false)) as repositories don't change.

#### Offline support

See the provided offline adapter!

#### Can I group adapter mixins into one?

No. https://stackoverflow.com/questions/59248686/how-to-group-mixins-in-dart

#### Where does Flutter Data generate code?

 - in `*.g.dart` files (part of your models)
 - in `main.data.dart` (as a library)

#### Can I use mutable classes?

Immutable models are strongly recommended, equality is very important for things to work well. Use data classes like freezed or equality tools.

It is possible to use mutable classes such as `ChangeNotifier`s.

Even then, it is recommended to have relationships (`BelongsTo`, `HasMany`) as final fields. If they are reassigned via a setter, the model MUST be manually reinitialized (`model.init()`) or relationship mappings WILL break.

#### Why is model.save() not available?

`DataSupport` extensions are syntax sugar and will ONLY work when importing Flutter Data in the corresponding file:

```dart
import 'package:flutter_data/flutter_data.dart';
```

#### Local storage for long term persistence

tl;dr don't save anything critical (with Flutter Data) just yet

  - Flutter Data is in alpha state and therefore there are no guarantees: APIs WILL change, local formats WILL change (this is why `clear=true` by default, meaning that local storage will be wiped out when the app restarts)
  - Additionally, we are waiting until Hive 2 comes out

#### Can only used id of type dynamic in Freezed?

You can use any type, but you have to parameterize it via `IdDataSupport`:

```dart
@freezed
@DataRepository([JSONAPIAdapter, BaseAdapter])
abstract class Account extends IdDataSupport<String, Account> implements _$Account {
  // ...
}
```

#### How can I declare the inverse relationship?

At the moment, the inverse relationship is looked up by type and it's not configurable. This will be fixed.

### Is Flutter Data a state management solution?

Yes. It is essentially a stream/stream controller combo. Couple it with a DI like Provider or get_it (or the included service locator) and you're set.

Want to use streams? Call `repo.watchAll().stream`.

Want to use `StateNotifier`s? Call `repo.watchAll()`.

https://www.reddit.com/r/FlutterDev/comments/fto3nt/use_hive_db_instead_of_other_state_management/

### Polymorphism

```dart
abstract class User<T extends User<T>> extends DataSupport<T> {
  final String id;
  final String name;
  User({this.id, this.name});
}

@JsonSerializable()
@DataRepository([JSONAPIAdapter, BaseAdapter])
class Customer extends User<Customer> {
  final String abc;
  Customer({String id, String name, this.abc}) : super(id: id, name: name);
}

@JsonSerializable()
@DataRepository([JSONAPIAdapter, BaseAdapter])
class Staff extends User<Staff> {
  final String xyz;
  Staff({String id, String name, this.xyz}) : super(id: id, name: name);
}
```

## ➕ Questions and collaborating

Please use Github to ask questions, open issues and send PRs. Thanks!

You can also hit me up on Twitter [@thefrank06](https://twitter.com/thefrank06)

Tests can be run with: `pub run test`

## 📝 License

See [LICENSE](https://github.com/flutterdata/flutter_data/blob/master/LICENSE).