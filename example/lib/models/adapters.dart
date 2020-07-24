import 'package:flutter_data/flutter_data.dart';

mixin JSONServerAdapter<T extends DataModel<T>> on RemoteAdapter<T> {
  @override
  String get baseUrl => 'https://my-json-server.typicode.com/flutterdata/demo/';

  @override
  String get identifierSuffix => 'Id';
}
