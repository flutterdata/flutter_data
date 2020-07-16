import 'package:meta/meta.dart';
import 'package:flutter_data/flutter_data.dart';
import 'package:json_annotation/json_annotation.dart';

import 'adapters.dart';

part 'user.g.dart';

@JsonSerializable()
@DataRepository([JSONServerAdapter])
class User with DataSupport<User> {
  @override
  final int id;
  final String name;
  final String email;

  User({this.id, this.name, @required this.email});
}
