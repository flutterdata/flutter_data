part of flutter_data;

typedef FutureFn<R> = FutureOr<R> Function();

class DataHelpers {
  static final uuid = Uuid();

  static final _internalTypes = <Object, String>{};

  static String getInternalType<T>() {
    if (T == dynamic) {
      throw UnsupportedError('Please supply a type');
    }
    return _internalTypes[T]!;
  }

  static void setInternalType<T>(String type) {
    if (!_internalTypes.containsKey(T)) {
      _internalTypes[T] = type;
    }
  }

  static String internalTypeFor(String type) => type.decapitalize().pluralize();

  static String generateShortKey<T>() {
    return uuid.v1().substring(0, 6);
  }

  static String generateKey<T>([String? type]) {
    if (type != null) {
      type = internalTypeFor(type);
    } else {
      type = getInternalType<T>();
    }
    return uuid.v1().substring(0, 8).typifyWith(type);
  }
}

class OfflineException extends DataException {
  OfflineException({required Object error}) : super(error);
  @override
  String toString() {
    return 'OfflineException: $error';
  }
}

abstract class _Lifecycle {
  @protected
  @visibleForTesting
  bool get isInitialized;

  void dispose();
}

class InternalHolder<T extends DataModel<T>> {
  final Map<String, dynamic> finders;
  InternalHolder(this.finders);
}

// finders

class DataFinder {
  const DataFinder();
}

typedef DataFinderAll<T extends DataModel<T>> = Future<List<T>?> Function({
  bool? remote,
  bool? background,
  Map<String, dynamic>? params,
  Map<String, String>? headers,
  bool? syncLocal,
  OnSuccessAll<T>? onSuccess,
  OnErrorAll<T>? onError,
  DataRequestLabel? label,
});

typedef DataFinderOne<T extends DataModel<T>> = Future<T?> Function(
  Object model, {
  bool? remote,
  bool? background,
  Map<String, dynamic>? params,
  Map<String, String>? headers,
  OnSuccessOne<T>? onSuccess,
  OnErrorOne<T>? onError,
  DataRequestLabel? label,
});

typedef DataWatcherAll<T extends DataModel<T>> = DataStateNotifier<List<T>?>
    Function({
  bool? remote,
  Map<String, dynamic>? params,
  Map<String, String>? headers,
  bool? syncLocal,
  String? finder,
  DataRequestLabel? label,
});

typedef DataWatcherOne<T extends DataModel<T>> = DataStateNotifier<T?> Function(
  Object model, {
  bool? remote,
  Map<String, dynamic>? params,
  Map<String, String>? headers,
  AlsoWatch<T>? alsoWatch,
  String? finder,
  DataRequestLabel? label,
});

// watch

typedef Watcher = W Function<W>(ProviderListenable<W> provider);

// relationships + alsoWatch

class RelationshipGraphNode<T extends DataModel<T>> {}

class RelationshipMeta<T extends DataModel<T>>
    with RelationshipGraphNode<T>, EquatableMixin {
  final String name;
  final String? inverseName;
  final String type;
  final String kind;
  final bool serialize;
  final Relationship? Function(DataModel) instance;
  RelationshipMeta? parent;
  RelationshipMeta? child;

  RelationshipMeta({
    required this.name,
    this.inverseName,
    required this.type,
    required this.kind,
    this.serialize = true,
    required this.instance,
  });

  // get topmost parent
  RelationshipMeta get _top {
    RelationshipMeta? current = this;
    while (current?.parent != null) {
      current = current!.parent;
    }
    return current!;
  }

  RelationshipMeta<T> clone({RelationshipMeta? parent}) {
    final meta = RelationshipMeta<T>(
      name: name,
      type: type,
      kind: kind,
      instance: instance,
    );
    if (parent != null) {
      meta.parent = parent;
      meta.parent!.child = meta; // automatically set child
    }
    return meta;
  }

  @override
  List<Object?> get props => [name, inverseName, type, kind, serialize];
}

typedef AlsoWatch<T extends DataModel<T>> = Iterable<RelationshipGraphNode>
    Function(RelationshipGraphNode<T>);

/// This argument holder class is used internally with
/// Riverpod `family`s.
class WatchArgs<T extends DataModel<T>> with EquatableMixin {
  WatchArgs({
    this.key,
    this.remote,
    this.params,
    this.headers,
    this.syncLocal,
    this.relationshipMetas,
    this.alsoWatch,
    this.finder,
    this.label,
  });

  final String? key;
  final bool? remote;
  final Map<String, dynamic>? params;
  final Map<String, String>? headers;
  final bool? syncLocal;
  final List<RelationshipMeta>? relationshipMetas;
  final AlsoWatch<T>? alsoWatch;
  final String? finder;
  final DataRequestLabel? label;

  @override
  List<Object?> get props => [
        key,
        remote,
        params,
        headers,
        syncLocal,
        relationshipMetas,
        finder,
        label
      ];
}

// ignore: constant_identifier_names
enum DataRequestMethod { GET, HEAD, POST, PUT, PATCH, DELETE, OPTIONS, TRACE }

extension _ToStringX on DataRequestMethod {
  String toShortString() => toString().split('.').last;
}

typedef _OnSuccessGeneric<R> = FutureOr<R?> Function(
    DataResponse data, DataRequestLabel label);
typedef OnSuccessOne<T extends DataModel<T>> = FutureOr<T?> Function(
    DataResponse data, DataRequestLabel label, RemoteAdapter<T> adapter);
typedef OnSuccessAll<T extends DataModel<T>> = FutureOr<List<T>?> Function(
    DataResponse data, DataRequestLabel label, RemoteAdapter<T> adapter);

typedef _OnErrorGeneric<R> = FutureOr<R?> Function(
    DataException e, DataRequestLabel label);
typedef OnErrorOne<T extends DataModel<T>> = FutureOr<T?> Function(
    DataException e, DataRequestLabel label, RemoteAdapter<T> adapter);
typedef OnErrorAll<T extends DataModel<T>> = FutureOr<List<T>?> Function(
    DataException e, DataRequestLabel label, RemoteAdapter<T> adapter);

/// Data request information holder.
///
/// Format examples:
///  - findAll/reports@b5d14c
///  - findOne/inspections#3@c4a1bb
///  - findAll/reports@b5d14c<c4a1bb
class DataRequestLabel with EquatableMixin {
  final String kind;
  final String type;
  final String? id;
  DataModel? model;
  final timestamp = DateTime.now();
  final _requestIds = <String>[];

  String get requestId => _requestIds.first;
  int get indentation => _requestIds.length - 1;

  DataRequestLabel(
    String kind, {
    required this.type,
    this.id,
    String? requestId,
    this.model,
    DataRequestLabel? withParent,
  }) : kind = kind.trim() {
    assert(!type.contains('#'));
    if (id != null) {
      assert(!id!.contains('#'));
    }
    if (requestId != null) {
      assert(!requestId.contains('@'));
    }
    _requestIds.add(requestId ?? DataHelpers.generateShortKey());

    if (withParent != null) {
      _requestIds.addAll(withParent._requestIds);
    }
  }

  factory DataRequestLabel.parse(String text) {
    final parts = text.split('/');
    final parts2 = parts.last.split('@');
    final parts3 = parts2[0].split('#');
    final kind = (parts..removeLast()).join('/');
    final requestId = parts2[1];
    final type = parts3[0];
    final id = parts3.length > 1 ? parts3[1] : null;

    return DataRequestLabel(kind, type: type, id: id, requestId: requestId);
  }

  @override
  String toString() {
    return '$kind/${(id ?? '').typifyWith(type)}@${_requestIds.join('<')}';
  }

  @override
  List<Object?> get props => [kind, type, id, _requestIds];
}

class DataResponse {
  final Object? body;
  final int statusCode;
  final Map<String, String> headers;

  const DataResponse(
      {this.body, required this.statusCode, this.headers = const {}});
}

class ValueNotifier<E> extends StateNotifier<E> {
  Function? onDispose;
  ValueNotifier(E value) : super(value);

  void updateWith(E value) => state = value;

  @override
  dispose() {
    onDispose?.call();
    super.dispose();
  }
}

/// ONLY FOR FLUTTER DATA INTERNAL USE
final internalRepositories = <String, Repository>{};
