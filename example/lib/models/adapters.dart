import 'package:flutter_data/flutter_data.dart';

mixin JSONServerAdapter<T extends DataModel<T>> on Adapter<T> {
  @override
  String get baseUrl => 'https://my-json-server.typicode.com/flutterdata/demo/';

  // URLs are built based on the type, and type on the internalType by default
  // Since we have 'todos' as internalType for Tasks, but we want to fetch
  // 'tasks', we need to override type:
  @override
  String get type => super.type == 'todos' ? 'tasks' : super.type;
}
