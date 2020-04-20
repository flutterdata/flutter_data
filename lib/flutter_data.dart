library flutter_data;

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:data_state/data_state.dart';
import 'package:json_api/query.dart';
import 'package:json_api/url_design.dart';
import 'package:meta/meta.dart';
import 'package:http/http.dart' as http;
import 'package:inflection2/inflection2.dart';
import 'package:path/path.dart' as path_helper;
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:rxdart/rxdart.dart';

export 'package:data_state/data_state.dart';

export 'annotations.dart';
export 'src/adapter/remote/json_api_adapter.dart';
export 'src/adapter/remote/offline_adapter.dart';
export 'src/adapter/remote/standard_json_adapter.dart';

part 'src/adapter/local/data_manager.dart';
part 'src/adapter/local_adapter.dart';

part 'src/model/data/data_id.dart';
part 'src/model/data/data_exception.dart';
part 'src/model/data/data_support.dart';
part 'src/model/relationship/relationship.dart';
part 'src/model/relationship/has_many.dart';
part 'src/model/relationship/belongs_to.dart';

part 'src/repository/repository.dart';

part 'src/util/extensions.dart';
part 'src/util/service_locator.dart';

DataManager _autoModelInitDataManager;

// https://github.com/dart-lang/pana/issues/604
@deprecated
void doNotUse() {}
