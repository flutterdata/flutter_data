# Flutter Data

Imagine annotating your models and magically getting:

 - instant API access and serialization
 - first-class relationship support
 - offline capabilities
 - streaming
 - multiple data sources support
 - and much more

with zero boilerplate.

```dart
// your model

@freezed
@DataRepository([StandardJSONAdapter, JSONPlaceholderAdapter])
abstract class Todo extends DataSupport<Todo> implements _$Todo {
  Todo._();
  factory Todo({ String id, String title }) = _Todo;
  // ...
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

It's configurable and composable. **Simple should be easy, complex should be possible.**

Fully compatible with the tools we know and love:

 - `json_serializable`
 - `provider`
 - streams / bloc
 - `freezed`
 - `state_notifier`
 - and many more

...and requires none (*except `json_serializable`* – for now!)

It can connect to any JSON API. It's bundled with a "standard" JSON adapter and a JSON:API adapter. For example, a JWT auth or Github adapter are trivial to make. Firebase and more adapters are coming soon!

Of course, it's super easy to customize without polluting your classes with a thousand annotations.

## Usage

### Annotating your models

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

(Flutter Data will add a few generated classes to your `model.g.dart` file.)

Ready!

A few notes about our configuration:

 - Yes, you can use `freezed` or other immutable data structure, and you can combine them
 - Models must extend `DataSupport<T>` for the magic to happen (or mix in `DataSupportMixin<T>`, but you'll have to manually initialize new models)
 - Models must declare a `fromJson` factory
 - `BelongsTo` and `HasMany` are relationships to help you traverse the object graph
 - `StandardJSONAdapter` is a bundled adapter to access standard REST APIs
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

### Configure and boot

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
    return MaterialApp(
// ...
```

Flutter Data auto-generated the `main.data.dart` library so everything is ready to for use.

Don't use Provider?

```dart

```

Don't use Flutter?

```dart

```

### Use


### Extend

 - can easily override findOne(id) => super.findOne(id) in mixin
 - or can extend/supply new urlDesign

To use:

```dart
(adapter as MyAdapterMixin).customFindAll()
```

show scout adapters

- withHttpClient transform in persistent connection (see how i did that for scout)

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

#### Can i use mutable classes?

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

## ➕ Collaborating

Please use Github to ask questions, open issues and send PRs. Thanks!

## 📝 License

MIT

(see the LICENSE file)