part of flutter_data;

/// A mixin to "tag" and ensure the implementation of an [id] getter
/// in data classes managed through Flutter Data.
///
/// It contains private state and methods to track the model's identity.
abstract class DataModel<T extends DataModel<T>> {
  Object? get id;

  // internal
  String? _key;
  Map<String, RemoteAdapter>? _adapters;
  String get _internalType => DataHelpers.getType<T>();
  DataStateNotifier<T?>? _notifier;

  /// Exposes this type's [RemoteAdapter]
  RemoteAdapter<T> get remoteAdapter =>
      _adapters?[_internalType]! as RemoteAdapter<T>;

  /// Exposes the [DataStateNotifier] that fetched this model;
  /// typically used to access `notifier.reload()`.
  /// ONLY available if loaded via [_RemoteAdapterWatch.watchOneNotifier].
  DataStateNotifier<T?>? get notifier => _notifier;

  /// Whether this model was initialized, either
  /// automatically or manually via `init` or [was].
  bool get isInitialized => _key != null && _adapters != null;

  // methods

  T refresh() {
    _assertInit('refresh');
    return remoteAdapter.localAdapter.findOne(_key)!;
  }

  // initializers

  T _initialize(final Map<String, RemoteAdapter> adapters,
      {String? key, bool save = false}) {
    if (isInitialized) {
      return this as T;
    }

    _adapters = adapters;

    _key = remoteAdapter.graph.getKeyForId(remoteAdapter.internalType, id,
        keyIfAbsent: key ?? DataHelpers.generateKey<T>());

    _initializeRelationships();

    if (save) {
      remoteAdapter.localAdapter.save(_key!, this as T);
    }

    return this as T;
  }

  void _initializeRelationships() {
    assert(isInitialized);

    for (final metadata
        in remoteAdapter.localAdapter.relationshipsFor(this as T).entries) {
      final relationship = metadata.value['instance'] as Relationship?;

      relationship?.initialize(
        adapters: _adapters!,
        owner: this,
        name: metadata.value['name'] as String,
        inverseName: metadata.value['inverse'] as String?,
      );
    }
  }

  // privately set the notifier
  void _updateNotifier(DataStateNotifier<T?>? value) {
    _notifier = value;
  }
}

/// Extension that adds syntax-sugar to data classes,
/// linking them to common [Repository] methods such as
/// [save] and [delete].
extension DataModelExtension<T extends DataModel<T>> on DataModel<T> {
  /// Initializes a model copying the identity of supplied [model].
  ///
  /// Usage:
  /// ```
  /// final post = await repository.findOne('1'); // returns initialized post
  /// final newPost = Post(title: 'test'); // uninitialized post
  /// newPost.was(post); // new is now initialized with same key as post
  /// ```
  T was(T model) {
    assert(model.isInitialized,
        'Please initialize model before passing it to `was`');
    if (model.id != null) {
      assert(id == model.id,
          'Should not use `was` with a model of a different ID');
    }
    return _initialize(model._adapters!, key: model._key, save: true);
  }

  /// Saves this model through a call equivalent to [Repository.save].
  ///
  /// Usage: `await post.save()`, `author.save(remote: false, params: {'a': 'x'})`.
  ///
  /// **Requires this model to be initialized.**
  Future<T> save({
    bool? remote,
    Map<String, dynamic>? params,
    Map<String, String>? headers,
    OnSuccess<T>? onSuccess,
    OnError<T>? onError,
  }) async {
    _assertInit('save');
    return await remoteAdapter.save(
      this as T,
      remote: remote,
      params: params,
      headers: headers,
      onSuccess: onSuccess,
      onError: onError,
    );
  }

  /// Deletes this model through a call equivalent to [Repository.delete].
  ///
  /// Usage: `await post.delete()`
  ///
  /// **Requires this model to be initialized.**
  Future<Null> delete({
    bool? remote,
    Map<String, dynamic>? params,
    Map<String, String>? headers,
    OnSuccess<Null>? onSuccess,
    OnError<Null>? onError,
  }) async {
    _assertInit('delete');
    await remoteAdapter.delete(
      this,
      remote: remote,
      params: params,
      headers: headers,
      onSuccess: onSuccess,
      onError: onError,
    );
  }

  /// Re-fetch this model through a call equivalent to [Repository.findOne].
  /// with the current object/[id]
  ///
  /// **Requires this model to be initialized.**
  Future<T?> reload({
    bool? remote,
    Map<String, dynamic>? params,
    Map<String, String>? headers,
  }) async {
    _assertInit('reload');
    return await remoteAdapter.findOne(
      this,
      remote: remote,
      params: params,
      headers: headers,
    );
  }

  /// Get all non-null [Relationship]s for this model.
  Iterable<Relationship> relationships({bool withValue = false}) {
    _assertInit('relationships');
    var rels = remoteAdapter.localAdapter
        .relationshipsFor(this as T)
        .values
        .map((e) => e['instance'] as Relationship?)
        .filterNulls;

    if (withValue) {
      rels = rels.where((r) => r is BelongsTo ? r.value != null : true);
    }

    return rels;
  }

  void _assertInit(String method) {
    if (isInitialized) {
      return;
    }
    throw AssertionError('''\n
This model MUST be initialized in order to call `$method`.

DON'T DO THIS:

  final ${_internalType.singularize()} = $T(...);
  ${_internalType.singularize()}.$method(...);

DO THIS:

  final ${_internalType.singularize()} = $T(...).init(ref.read);
  ${_internalType.singularize()}.$method(...);

Call `init(ref.read)` on the model first.

This ONLY happens when a model is manually instantiated
and had no contact with Flutter Data.

Initializing models is not necessary in any other case.

When assigning new models to a relationship, only initialize
the actual model:

Family(surname: 'Carlson', dogs: {Dog(name: 'Jerry'), Dog(name: 'Zoe')}.asHasMany)
  .init(ref.read);
''');
  }
}

/// Returns a model's `_key` private attribute.
///
/// Useful for testing, debugging or usage in [RemoteAdapter] subclasses.
String? keyFor<T extends DataModel<T>>(T model) => model._key;

@visibleForTesting
@protected
RemoteAdapter? adapterFor<T extends DataModel<T>>(T model) =>
    model.remoteAdapter;
