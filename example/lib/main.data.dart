// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: directives_ordering, top_level_function_literal_block, depend_on_referenced_packages

import 'package:flutter_data/flutter_data.dart';

import 'package:jsonplaceholder_example/models/task.dart';
import 'package:jsonplaceholder_example/models/user.dart';

final adapterProviders = <String, Provider<Adapter<DataModelMixin>>>{
  'tasks': tasksAdapterProvider,
  'users': usersAdapterProvider
};

extension AdapterRefX on ProviderContainer {
  E watch<E>(ProviderListenable<E> provider) {
    return readProviderElement(provider as ProviderBase<E>).readSelf();
  }

  Adapter<Task> get tasks => watch(tasksAdapterProvider)..internalWatch = watch;
  Adapter<User> get users => watch(usersAdapterProvider)..internalWatch = watch;
}
