import 'package:flutter_data/flutter_data.dart';
import 'package:json_annotation/json_annotation.dart';

import 'adapters.dart';
import 'task.dart';

part 'user.g.dart';

@JsonSerializable()
@DataRepository([JSONServerAdapter])
class User with DataModel<User> {
  @override
  final int? id;
  final String name;
  late final HasMany<Task> tasks;

  User({this.id, required this.name, HasMany<Task>? tasks})
      : tasks = tasks ?? HasMany();
}
