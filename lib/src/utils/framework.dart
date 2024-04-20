part of flutter_data;

typedef FutureFn<R> = FutureOr<R> Function();

class DataHelpers {
  static final rng = Random.secure();

  static String internalTypeFor(String type) => type.decapitalize().pluralize();

  static int _generateRandomNumber() {
    return (rng.nextDouble() * 9223372036854775807).toInt();
  }

  static String generateShortKey() {
    return _generateRandomNumber().toString().substring(0, 10);
  }
}

class OfflineException extends DataException {
  OfflineException({required Object error}) : super(error);
  @override
  String toString() {
    return 'OfflineException: $error';
  }
}

mixin _Lifecycle {
  @protected
  @visibleForTesting
  bool get isInitialized;

  void dispose();
}

class InternalHolder<T extends DataModelMixin<T>> {
  final Map<String, dynamic> finders;
  InternalHolder(this.finders);
}

// finders

class DataFinder {
  const DataFinder();
}

typedef DataFinderAll<T extends DataModelMixin<T>> = Future<List<T>> Function({
  bool? remote,
  bool? background,
  Map<String, dynamic>? params,
  Map<String, String>? headers,
  bool? syncLocal,
  OnSuccessAll<T>? onSuccess,
  OnErrorAll<T>? onError,
  DataRequestLabel? label,
});

typedef DataFinderOne<T extends DataModelMixin<T>> = Future<T?> Function(
  Object model, {
  bool? remote,
  bool? background,
  Map<String, dynamic>? params,
  Map<String, String>? headers,
  OnSuccessOne<T>? onSuccess,
  OnErrorOne<T>? onError,
  DataRequestLabel? label,
});

typedef DataWatcherAll<T extends DataModelMixin<T>> = DataStateNotifier<List<T>>
    Function({
  bool? remote,
  Map<String, dynamic>? params,
  Map<String, String>? headers,
  bool? syncLocal,
  String? finder,
  DataRequestLabel? label,
});

typedef DataWatcherOne<T extends DataModelMixin<T>> = DataStateNotifier<T?>
    Function(
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

mixin class RelationshipGraphNode<T extends DataModelMixin<T>> {}

class RelationshipMeta<T extends DataModelMixin<T>>
    with RelationshipGraphNode<T>, EquatableMixin {
  final String name;
  final String? inverseName;
  final String type;
  final String kind;
  final bool serialize;
  final Relationship? Function(DataModelMixin) instance;
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
  // RelationshipMeta get _top {
  //   RelationshipMeta? current = this;
  //   while (current?.parent != null) {
  //     current = current!.parent;
  //   }
  //   return current!;
  // }

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

typedef AlsoWatch<T extends DataModelMixin<T>> = Iterable<RelationshipGraphNode>
    Function(RelationshipGraphNode<T>);

/// This argument holder class is used internally with
/// Riverpod `family`s.
class WatchArgs<T extends DataModelMixin<T>> with EquatableMixin {
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
    DataResponse response, DataRequestLabel label);
typedef OnSuccessOne<T extends DataModelMixin<T>> = FutureOr<T?> Function(
    DataResponse response, DataRequestLabel label, Adapter<T> adapter);
typedef OnSuccessAll<T extends DataModelMixin<T>> = FutureOr<List<T>> Function(
    DataResponse response, DataRequestLabel label, Adapter<T> adapter);

typedef _OnErrorGeneric<R> = FutureOr<R?> Function(
    DataException e, DataRequestLabel label);
typedef OnErrorOne<T extends DataModelMixin<T>> = FutureOr<T?> Function(
    DataException e, DataRequestLabel label, Adapter<T> adapter);
typedef OnErrorAll<T extends DataModelMixin<T>> = FutureOr<List<T>> Function(
    DataException e, DataRequestLabel label, Adapter<T> adapter);

/// Data request information holder.
///
/// Format examples:
///  - findAll/reports@b5d14c
///  - findOne/inspections#3@c4a1bb
///  - findAll/reports@b5d14c<c4a1bb
class DataRequestLabel with EquatableMixin {
  final String kind;
  final String _typeId;
  DataModelMixin? model;
  final timestamp = DateTime.now();
  final _requestIds = <String>[];

  String get type => _typeId.split('#').first;
  Object? get id => _typeId.detypify();

  String get requestId => _requestIds.first;
  int get indentation => _requestIds.length - 1;

  DataRequestLabel(
    String kind, {
    required String type,
    Object? id,
    String? requestId,
    this.model,
    DataRequestLabel? withParent,
  })  : _typeId = id.typifyWith(type),
        kind = kind.trim() {
    if (requestId != null) {
      // TODO what is @ , also: should change that ints are now # (not ##)
      assert(!requestId.contains('@'));
    }
    _requestIds.add(requestId ?? DataHelpers.generateShortKey());

    if (withParent != null) {
      _requestIds.addAll(withParent._requestIds);
    }
  }

  // findOne/watch/dogs#1@7ebcc6
  factory DataRequestLabel.parse(String text) {
    final [...kindParts, label] = text.split('/');
    final [typeId, requestId] = label.split('@');
    final [type, ..._] = typeId.split('#');
    final id = typeId.detypify();
    return DataRequestLabel(kindParts.join('/'),
        type: type, id: id, requestId: requestId);
  }

  @override
  String toString() {
    return '$kind/$_typeId@${_requestIds.join('<')}';
  }

  @override
  List<Object?> get props => [kind, _typeId, _requestIds];
}

class DataResponse {
  final Object? body;
  final int statusCode;
  final Map<String, String> headers;

  const DataResponse(
      {this.body, required this.statusCode, this.headers = const {}});
}

Map<String, Provider<Adapter<DataModelMixin>>>? _internalProviders;
Map<String, Adapter>? _internalAdapters;

R logTime<R>(String? name, R cb()) {
  if (name == null) return cb();
  final a1 = DateTime.now().millisecondsSinceEpoch;
  final result = cb();
  final a2 = DateTime.now().millisecondsSinceEpoch;
  print('$name: ${a2 - a1}ms');
  return result;
}

Future<R> logTimeAsync<R>(String? name, Future<R> cb()) async {
  if (name == null) return await cb();
  final a1 = DateTime.now().millisecondsSinceEpoch;
  final result = await cb();
  final a2 = DateTime.now().millisecondsSinceEpoch;
  print('$name: ${a2 - a1}ms');
  return result;
}

@protected
mixin NothingMixin {}

final initializeWith =
    FutureProvider.family<bool, Map<String, Provider<Adapter<DataModelMixin>>>>(
        (ref, adapterProviders) async {
  _internalProviders = adapterProviders;
  _internalAdapters =
      adapterProviders.map((key, value) => MapEntry(key, ref.read(value)));

  await ref.read(localStorageProvider).initialize();

  // initialize and register
  for (final adapter in _internalAdapters!.values) {
    adapter.dispose();
    await adapter.initialize(ref: ref);
  }

  return true;
});
