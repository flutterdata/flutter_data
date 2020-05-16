library flutter_data;

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:data_state/data_state.dart';
import 'package:flutter_data/src/util/graph_notifier.dart';
import 'package:meta/meta.dart';
import 'package:http/http.dart' as http;
import 'package:inflection2/inflection2.dart';
import 'package:path/path.dart' as path_helper;
import 'package:rxdart/rxdart.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'src/util/notifier_extension.dart';

export 'package:data_state/data_state.dart';

export 'adapters/json_api_adapter.dart';
export 'adapters/offline_adapter.dart';
export 'adapters/standard_json_adapter.dart';
export 'annotations.dart';

part 'src/data_manager.dart';
part 'src/repository/util/hive_adapter.dart';
part 'src/repository/adapter/remote_adapter.dart';
part 'src/repository/adapter/watch_adapter.dart';

part 'src/data/data_id.dart';
part 'src/data/data_exception.dart';
part 'src/model/data_support.dart';
part 'src/model/relationship/relationship.dart';
part 'src/model/relationship/has_many.dart';
part 'src/model/relationship/belongs_to.dart';

part 'src/repository/repository.dart';

part 'src/data/extensions.dart';
part 'src/util/service_locator.dart';

DataManager _autoModelInitDataManager;

// https://github.com/dart-lang/pana/issues/604
@deprecated
void doNotUse() {}
