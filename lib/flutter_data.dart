library flutter_data;

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:data_state/data_state.dart';
import 'package:state_notifier/state_notifier.dart';
import 'package:json_api/document.dart' hide Relationship;
import 'package:json_api/query.dart';
import 'package:json_api/url_design.dart';
import 'package:meta/meta.dart';
import 'package:http/http.dart' as http;
import 'package:inflection2/inflection2.dart';
import 'package:path/path.dart' as path_helper;
import 'package:hive/hive.dart';
import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';

export 'package:data_state/data_state.dart';
export 'package:state_notifier/state_notifier.dart' show Locator;

export 'src/adapter/remote/offline_retry_adapter.dart';
export 'src/adapter/remote/standard_json_adapter.dart';

part 'src/adapter/local/data_manager.dart';
part 'src/adapter/local_adapter.dart';
part 'src/adapter/remote_adapter.dart';

part 'src/model/data/data_id.dart';
part 'src/model/data/data_exception.dart';
part 'src/model/data/data_support.dart';
part 'src/model/relationship/relationship.dart';
part 'src/model/relationship/has_many.dart';
part 'src/model/relationship/belongs_to.dart';

part 'src/repository/repository.dart';

part 'src/util/extensions.dart';
part 'src/util/service_locator.dart';
