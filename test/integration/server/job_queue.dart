import 'dart:async';

import 'package:json_api/document.dart';
import 'package:uuid/uuid.dart';

class Job {
  final String id;

  String get status => resource == null ? 'pending' : 'complete';
  Resource resource;

  Job(Future<Resource> create) : id = Uuid().v4() {
    create.then((_) => resource = _);
  }
}
