import 'package:flutter_data/flutter_data.dart';
import 'package:json_annotation/json_annotation.dart';

import 'adapters.dart';
import 'user.dart';

part 'task.g.dart';

@JsonSerializable()
@DataRepository([JSONServerAdapter])
class Task with DataModel<Task> {
  @override
  final int? id;
  final String title;
  final bool completed;
  final BelongsTo<User>? user;

  Task({this.id, required this.title, this.completed = false, this.user});
}
