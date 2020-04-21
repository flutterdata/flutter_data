<p align="center" style="margin-bottom: 0px;">
  <img src="https://avatars2.githubusercontent.com/u/61839689?s=200&v=4" width="85px">
</p>

<h1 align="center" style="margin-top: 0px; font-size: 4em;">Flutter Data</h1>

[![tests](https://img.shields.io/github/workflow/status/flutterdata/flutter_data/test/master?label=tests&labelColor=333940&logo=github)](https://github.com/flutterdata/flutter_data/actions) [![pub.dev](https://img.shields.io/pub/v/flutter_data?label=pub.dev&labelColor=333940&logo=dart)](https://pub.dev/packages/flutter_data) [![license](https://img.shields.io/github/license/flutterdata/flutter_data?color=%23007A88&labelColor=333940&logo=mit)](https://github.com/flutterdata/flutter_data/blob/master/LICENSE)

Flutter Data is a library for seamlessly managing persistent data in Flutter apps.

Inspired by [Ember Data](https://github.com/emberjs/data) and [ActiveRecord](https://guides.rubyonrails.org/active_record_basics.html), it enables the use and creation of persistent business models in the reactive Flutter environment.

It is naturally suited for **offline-first** applications.

### Check out the [Documentation](https://flutterdata.dev) or the [5-Minute Tutorial](https://flutterdata.dev/tutorial) 📚 

## Features

 - Automatic repositories for all models 📦
   - Retrieve/parse/store API data 🚀
   - Notifier, Future and Stream APIs ✅
 - Offline capabilities 🔌
 - Excellent relationship support 🎎
 - Truly configurable and composable 🧱
 - Intuitive API and minimal boilerplate 🤩
 - Scales well (both up and down) 📈 

## Getting started

See the [quickstart guide](https://flutterdata.dev/quickstart) in the docs.

## 👩🏾‍💻 Usage

For a given `User` model annotated with `@DataRepository`...

```dart
@JsonSerializable()
@DataRepository([StandardJSONAdapter, JSONPlaceholderAdapter])
class User extends DataSupport<User> {
  final int id;
  final String name;

  // ...
}
```

Flutter Data will generate a `Repository<User>` (after a source gen build):

```dart
// obtain it via Provider
final repository = context.read<Repository<User>>();

return DataStateBuilder<List<User>>(
  notifier: repository.watchAll();
  builder: (context, state, notifier, _) {
    // state.model is a list of 10 user items
    return ListView.builder(
      itemBuilder: (context, i) {
        if (state.isLoading) {
          return CircularProgressIndicator();
        }
        if (state.hasException) {
          return Text('Error: ${state.exception}');
        }
        return UserTile(state.model[i]);
      },
    );
  }
}
```

Here, `repository.watchAll()` will make an HTTP request (to `http://jsonplaceholder.typicode.com/users` in this case), parse the incoming JSON and listen for any further changes to the `User` collection – whether those are local or remote!

`state` is of type `DataState` which ships with loading/error/data substates. Moreover, `notifier.reload()` is available, useful for the classic "pull-to-refresh" scenario.

In addition to the reactivity, a `User` now gets extensions and automatic relationships, ActiveRecord-style:

```dart
final todo = await Todo(title: 'Finish docs').save();
// POST http://jsonplaceholder.typicode.com/todos/
print(todo.id); // 201

final user = await repository.findOne(1, params: { '_embed': 'todos' });
// GET http://jsonplaceholder.typicode.com/users/1?_embed=todos
print(user.todos.length); // 20

await user.todos.last.delete();
```

As easy as it looks!

For a detailed yet quick explanation, check out the **[5-Minute Tutorial](https://flutterdata.dev/tutorial)**!

Code for a simple yet **fully** functional app built with Flutter Data? See the finished **[Flutter Data TO-DOs Sample App](https://github.com/flutterdata/flutter_data_todos)**.

## 📲 Apps using Flutter Data

![](https://mk0scoutforpetsedheb.kinstacdn.com/wp-content/uploads/scout.svg)

The new offline-first [Scout](https://scoutforpets.com) Flutter app is being developed in record time with Flutter Data.

## ➕ Questions and collaborating

Please use Github to ask questions, open issues and send PRs. Thanks!

You can also hit me up on Twitter [@thefrank06](https://twitter.com/thefrank06)

Tests can be run with: `pub run test`

## 📝 License

See [LICENSE](https://github.com/flutterdata/flutter_data/blob/master/LICENSE).