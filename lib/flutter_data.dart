library flutter_data;

// import external packages
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' show Random;
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:http/http.dart' as http;
import 'package:inflection3/inflection3.dart' as inflection;
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path_helper;
import 'package:pool/pool.dart';
import 'package:riverpod/riverpod.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:state_notifier/state_notifier.dart';

// import internal packages
import 'src/core/core_notifier_extension.dart';

// export external packages
export 'package:riverpod/riverpod.dart' hide Family;

// export internal packages
export 'src/core/core_notifier_extension.dart';

part 'src/core/core_notifier.dart';
// include parts
part 'src/model/data_model.dart';
part 'src/model/relationship/belongs_to.dart';
part 'src/model/relationship/has_many.dart';
part 'src/model/relationship/relationship.dart';
part 'src/adapter/adapter.dart';
part 'src/adapter/remote_adapter.dart';
part 'src/adapter/serialization_adapter.dart';
part 'src/adapter/watch_adapter.dart';
part 'src/storage/local_storage.dart';
part 'src/storage/in_memory_local_storage.dart';
part 'src/utils/data_state.dart';
part 'src/utils/extensions.dart';
part 'src/utils/framework.dart';
part 'src/utils/offline_operations.dart';
