library flutter_data;

// import external packages
import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart';
import 'package:equatable/equatable.dart';
// import internal packages
import 'package:flutter_data/src/graph/notifier_extension.dart';
import 'package:flutter_data/src/repository/hive_local_storage.dart';
import 'package:flutter_data/src/utils/data_state.dart';
// import internal packages end
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:inflection3/inflection3.dart' as inflection;
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path_helper;
import 'package:riverpod/riverpod.dart';
import 'package:uuid/uuid.dart';

// export external packages
export 'package:riverpod/riverpod.dart' hide Family;

// export internal packages
export 'graph/notifier_extension.dart';
export 'repository/hive_local_storage.dart';
export 'utils/data_state.dart';

part 'graph/graph_notifier.dart';
// include parts
part 'model/data_model.dart';
part 'model/relationship/belongs_to.dart';
part 'model/relationship/has_many.dart';
part 'model/relationship/relationship.dart';
part 'repository/hive_local_adapter.dart';
part 'repository/local_adapter.dart';
part 'repository/remote_adapter.dart';
part 'repository/remote_adapter_offline.dart';
part 'repository/remote_adapter_serialization.dart';
part 'repository/remote_adapter_watch.dart';
part 'repository/repository.dart';
part 'utils/extensions.dart';
part 'utils/framework.dart';
part 'utils/initialization.dart';
