library flutter_data;

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:data_state/data_state.dart';
import 'package:riverpod/riverpod.dart';
import 'package:state_notifier/state_notifier.dart';
import 'package:meta/meta.dart';
import 'package:http/http.dart' as http;
import 'package:inflection2/inflection2.dart' as inflection;
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import 'src/graph/notifier_extension.dart';
import 'storage/hive_local_storage.dart';

export 'package:data_state/data_state.dart';
export 'package:riverpod/riverpod.dart' hide Family;
export 'src/graph/notifier_extension.dart';
export 'storage/hive_local_storage.dart';

part 'src/model/data_support.dart';
part 'src/model/relationship/relationship.dart';
part 'src/model/relationship/has_many.dart';
part 'src/model/relationship/belongs_to.dart';

part 'src/repository/remote_adapter.dart';
part 'src/repository/remote_adapter_serialization.dart';
part 'src/repository/remote_adapter_watch.dart';
part 'src/repository/repository.dart';
part 'src/repository/hive_local_adapter.dart';
part 'src/repository/local_adapter.dart';

part 'src/utils.dart';
part 'src/graph/graph_notifier.dart';
