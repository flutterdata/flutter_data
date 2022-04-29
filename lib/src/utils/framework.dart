part of flutter_data;

typedef FutureFn<R> = FutureOr<R> Function();

class DataHelpers {
  static final uuid = Uuid();

  static String getType<T>([String? type]) {
    if (T == dynamic && type == null) {
      throw UnsupportedError('Please supply a type');
    }
    type ??= T.toString();
    type = type.decapitalize();
    return type.pluralize();
  }

  static String generateShortKey<T>() {
    return uuid.v1().substring(0, 6);
  }

  static String generateKey<T>([String? type]) {
    type = getType<T>(type);
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

typedef AlsoWatch<T extends DataModel<T>> = Iterable<Relationship?> Function(T);

/// This argument holder class is used internally with
/// Riverpod `family`s.
class WatchArgs<T extends DataModel<T>> with EquatableMixin {
  WatchArgs({
    this.key,
    this.remote,
    this.params,
    this.headers,
    this.syncLocal,
    this.alsoWatch,
    this.finder,
    this.label,
  });

  final String? key;
  final bool? remote;
  final Map<String, dynamic>? params;
  final Map<String, String>? headers;
  final bool? syncLocal;
  final AlsoWatch<T>? alsoWatch;
  final String? finder;
  final DataRequestLabel? label;

  @override
  List<Object?> get props =>
      [key, remote, params, headers, syncLocal, finder, label];
}

// ignore: constant_identifier_names
enum DataRequestMethod { GET, HEAD, POST, PUT, PATCH, DELETE, OPTIONS, TRACE }

extension _ToStringX on DataRequestMethod {
  String toShortString() => toString().split('.').last;
}

typedef _OnSuccessGeneric<R> = FutureOr<R?> Function(
    Object? data, DataRequestLabel? label);
typedef OnSuccessOne<T extends DataModel<T>> = FutureOr<T?> Function(
    Object? data, DataRequestLabel? label, RemoteAdapter<T> adapter);
typedef OnSuccessAll<T extends DataModel<T>> = FutureOr<List<T>?> Function(
    Object? data, DataRequestLabel? label, RemoteAdapter<T> adapter);

typedef _OnErrorGeneric<R> = FutureOr<R?> Function(
    DataException e, DataRequestLabel? label);
typedef OnErrorOne<T extends DataModel<T>> = FutureOr<T?> Function(
    DataException e, DataRequestLabel? label, RemoteAdapter<T> adapter);
typedef OnErrorAll<T extends DataModel<T>> = FutureOr<List<T>?> Function(
    DataException e, DataRequestLabel? label, RemoteAdapter<T> adapter);

/// Data request information holder.
///
/// Format examples:
///  - findAll/reports@b5d14c
///  - findOne/inspections#3@c4a1bb
///  - findAll/reports@b5d14c<c4a1bb
class DataRequestLabel with EquatableMixin {
  final String kind;
  late final String type;
  final String? id;
  DataModel? model;
  final _requestIds = <String>[];

  String get requestId => _requestIds.first;
  int get indentation => _requestIds.length - 1;

  DataRequestLabel(
    String kind, {
    required String type,
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
    this.type = DataHelpers.getType(type);
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
