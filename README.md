<h1><img style="display: inline-block;" src="https://avatars2.githubusercontent.com/u/61839689?s=200&v=4" width="45px">Flutter Data</h1>

**Imagine annotating your models and magically getting:**

 - instant API access and serialization ⚡️
 - first-class relationship support 🎎
 - offline capabilities 🔌
 - streaming 🚰
 - multiple data sources support 🎛
 - and much more

with zero boilerplate!

```dart
// your model

@freezed
@DataRepository([StandardJSONAdapter, JSONPlaceholderAdapter])
abstract class Todo extends DataSupport<Todo> implements _$Todo {
  Todo._();
  factory Todo({ String id, String title }) = _Todo;
  factory Todo.fromJson(Map<String, dynamic> json) => _$TodoFromJson(json);
}

// your widget

return Scaffold(
  body: StreamBuilder<List<Todo>>(
    stream: context.read<Repository<Todo>>().watchAll().stream,
    builder: (context, snapshot) {
      return ListView.builder(
        itemBuilder: (context, i) {
          return Text('TO-DO! ${snapshot.data[i].title}'),
        },
        // ...
```

### Simple should be easy, complex should be possible

It's configurable, composable and fully compatible with the tools we know and love:

 - `json_serializable`
 - Provider
 - streams / bloc
 - `freezed`
 - `state_notifier`
 - Hive (it uses it under the hood)
 - and many more

...and requires none (*except `json_serializable`* – for now!)

It can connect to any JSON API. It's bundled with a "standard" JSON adapter and a JSON:API adapter. For example, a JWT auth or Github adapter are trivial to make. Firebase and more adapters are coming soon!

## 👩🏾‍💻 Usage

### 1. Annotate models

```dart
// models/todo.dart

@freezed
@DataRepository([StandardJSONAdapter, JSONPlaceholderAdapter])
abstract class Todo extends DataSupport<Todo> implements _$Todo {
  Todo._();
  factory Todo({
    String id,
    String title,
    @Default(false) bool completed,
    BelongsTo<User> user,
  }) = _Todo;

  factory Todo.fromJson(Map<String, dynamic> json) => _$TodoFromJson(json);
}

// models/user.dart

@JsonSerializable()
@DataRepository([StandardJSONAdapter, JSONPlaceholderAdapter])
class User extends DataSupport<User> {
  @override
  final String id;
  final String name;
  final String email;
  final HasMany<Todo> todos;

  User({
    this.id,
    @required this.name,
    this.email,
    this.todos,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}
```

And run:

```
flutter packages pub run build_runner build
```

(Flutter Data will add small generated classes to your `model.g.dart` file.)

**Ready! 🙌**

A few notes about the configuration above:

 - Yes, you can use `freezed` or other immutable data structure, and you can combine them
 - Models must extend `DataSupport<T>` for the magic to happen (or mix in `DataSupportMixin<T>`, but you'll have to manually initialize new models, e.g. `Todo(title: 'init').init(repo);`)
 - Models must declare a `fromJson` factory
 - `BelongsTo` and `HasMany` are relationships to help you traverse the object graph
 - `StandardJSONAdapter` is an adapter to access standard REST APIs (provided with Flutter Data)
 - `JSONPlaceholderAdapter` is a mixin we defined with our configurations!

```dart
mixin JSONPlaceholderAdapter<T extends DataSupport<T>> on StandardJSONAdapter<T> {
  @override
  String get baseUrl => 'https://jsonplaceholder.typicode.com/';

  @override
  String get identifierSuffix => 'Id';
}
```

There are a million ways to extend capabilities through adapters. We'll get to that later.

### 2. Configure and boot app

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
    _dir = await Directory('../tmp').create();
    final manager = await FlutterData.init(_dir);
    Locator locator = manager.locator;
    
    final repository = locator<Repository<User>>();
    // ...
  }
  // ...
}
```

### 3. Use it

#### Find models

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

The default behavior is to get models from local storage first
and then fetch models from the remote server in the background.

This strategy can easily be changed by overriding methods in a custom adapter.

#### Saving and deleting a model

```dart
final user = User(name: 'Frank Treacy').save();

// which is syntax sugar for writing
final user = repository.save(User(name: 'Frank Treacy'));

// only save locally
User(name: 'Frank Treacy').save(remote: false);

// delete user
user.delete();
```

#### Using relationships

Flutter Data has a powerful relationship mapping system.

Provided the API responds correctly with relationship data,
we can expect the following to work:

```dart
// recall that User has a HasMany<Todo> attribute
User user = repository.findOne('Frank');

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

### 4. Extend further

Let's say we need extra headers in our requests:

```dart
mixin BaseAdapter<T extends DataSupport<T>> on RemoteAdapter<T> {
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
mixin StupidAdapter<T extends DataSupport<T>> on RemoteAdapter<T> {
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
mixin AuthAdapter<DataSupport> on RemoteAdapter<User> {
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

#### Offline

Should be working, but much better support coming very soon!

#### Can I group adapter mixins into one?

https://stackoverflow.com/questions/59248686/how-to-group-mixins-in-dart

#### Where does Flutter Data generate code?

 - in `*.g.dart` files (part of your models)
 - in `main.data.dart` (as a library)

#### Can I use mutable classes?

Immutable models are strongly recommended, equality is very important for things to work well. Use data classes like freezed or equality tools.

It is possible to use mutable classes such as `ChangeNotifier`s.

Even then, it is recommended to have relationships (`BelongsTo`, `HasMany`) as final fields. If they are reassigned via a setter, the model MUST be manually reinitialized (`model.init()`) or relationship mappings WILL break.

#### Why model.save() is not available?

`DataSupport` extensions are syntax sugar and will ONLY work when importing Flutter Data in the corresponding file:

```dart
import 'package:flutter_data/flutter_data.dart';
```

#### Local storage for long term persistence

tl;dr don't save anything critical (with Flutter Data) just yet

  - Flutter Data is in alpha state and therefore there are no guarantees: APIs WILL change, local formats WILL change (this is why `clear=true` by default, meaning that local storage will be wiped out when the app restarts)
  - Additionally, we are waiting until Hive 2 comes out

#### id must be a String?
 
`id` must be a `String` for now.

use:

```dart
@JsonKey(fromJson: _stringToInt, toJson: _stringFromInt)
```

if you need to convert to `int`, for example.

#### How can I declare the inverse relationship?

At the moment, the inverse relationship is looked up by type and it's not configurable.

## ➕ Questions and collaborating

Please use Github to ask questions, open issues and send PRs. Thanks!

Tests can be run with: `pub run test`

## 📝 License

MIT

(see the LICENSE file)