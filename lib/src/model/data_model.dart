part of flutter_data;

/// A mixin to "tag" and ensure the implementation of an [id] getter
/// in data classes managed through Flutter Data.
///
/// It contains private state and methods to track the model's identity.
abstract class DataModel<T extends DataModel<T>> {
  Object? get id;

  DataModel() {
    final _isRepoInitialized = internalRepositories.containsKey(_internalType);
    if (_isRepoInitialized && remoteAdapter.autoInitializeModels) init();
  }

  String? __key;
  String get _key {
    if (__key == null) {
      throw AssertionError('Model must be initialized in order to get its key');
    }
    return __key!;
  }

  String get _internalType => DataHelpers.getType<T>();
  DataStateNotifier<T?>? _notifier;
  T get _this => this as T;

  bool get _isInitialized => __key != null;

  /// Exposes this type's [RemoteAdapter]
  RemoteAdapter<T> get remoteAdapter =>
      internalRepositories[_internalType]!.remoteAdapter as RemoteAdapter<T>;

  /// Exposes the [DataStateNotifier] that fetched this model;
  /// typically used to access `notifier.reload()`.
  /// ONLY available if loaded via [Repository.watchOneNotifier].
  DataStateNotifier<T?>? get notifier => _notifier;

  Map<String, RelationshipMeta> get relationshipMetas =>
      remoteAdapter.localAdapter.relationshipMetas;

  // methods

  T saveLocal() {
    remoteAdapter.localAdapter.save(_key, _this);
    return _this;
  }

  // privately set the notifier
  void _updateNotifier(DataStateNotifier<T?>? value) {
    _notifier = value;
  }

  // init

  T init({bool save = true}) {
    // ignore if already initialized
    if (_isInitialized) return _this;
    __key = remoteAdapter.graph.getKeyForId(_internalType, id,
        keyIfAbsent: DataHelpers.generateKey<T>())!;
    if (save) {
      remoteAdapter.localAdapter.save(_key, _this, notify: false);
    }
    getRelationships();
    return _this;
  }

  /// Copy identity (internal key) from an old model to a new one
  /// to signal they are the same.
  T was(T model, {bool ignoreId = false}) {
    init();
    if (model._key != _key) {
      T _old;
      T _new;

      // if the passed-in model has no ID
      // then treat the original as prevalent
      if (ignoreId == false && model.id == null && id != null) {
        _old = model;
        _new = _this;
      } else {
        // in all other cases, treat the passed-in
        // model as prevalent
        _old = _this;
        _new = model;
      }

      final _oldKey = _old._key;
      if (_key != _new._key) {
        __key = _new._key;
      }
      if (_key != _old._key) {
        _old.__key = _key;
        remoteAdapter.graph.removeKey(_oldKey);
      }

      if (_old.id != null) {
        remoteAdapter.graph.removeId(_internalType, _old.id!, notify: false);
        remoteAdapter.graph
            .getKeyForId(_internalType, _old.id, keyIfAbsent: _key);
      }
    }
    return _this;
  }

  /// Get all non-null [Relationship]s for this model.
  Iterable<Relationship> getRelationships() {
    final metadatas = remoteAdapter.localAdapter.relationshipMetas.values;

    return metadatas
        .map((metadata) {
          final relationship = metadata.instance(_this);
          return relationship?.initialize(
            owner: this,
            name: metadata.name,
            inverseName: metadata.inverseName,
          );
        })
        .toList()
        .filterNulls;
  }
}

/// Extension that adds syntax-sugar to data classes,
/// linking them to common [Repository] methods such as
/// [save] and [delete].
extension DataModelExtension<T extends DataModel<T>> on DataModel<T> {
  /// Saves this model through a call equivalent to [Repository.save].
  ///
  /// Usage: `await post.save()`, `author.save(remote: false, params: {'a': 'x'})`.
  Future<T> save({
    bool? remote,
    Map<String, dynamic>? params,
    Map<String, String>? headers,
    OnSuccessOne<T>? onSuccess,
    OnErrorOne<T>? onError,
  }) async {
    return await remoteAdapter.save(
      _this,
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
  Future<T?> delete({
    bool? remote,
    Map<String, dynamic>? params,
    Map<String, String>? headers,
    OnSuccessOne<T>? onSuccess,
    OnErrorOne<T>? onError,
  }) async {
    return await remoteAdapter.delete(
      this,
      remote: remote,
      params: params,
      headers: headers,
      onSuccess: onSuccess,
      onError: onError,
    );
  }

  /// Get the refreshed version from local storage.
  T? refresh() {
    return remoteAdapter.localAdapter.findOne(_key);
  }

  /// Re-fetch this model through a call equivalent to [Repository.findOne].
  /// with the current object/[id]
  Future<T?> reload({
    Map<String, dynamic>? params,
    Map<String, String>? headers,
    bool? background,
    DataRequestLabel? label,
  }) async {
    return await remoteAdapter.findOne(
      this,
      remote: true,
      params: params,
      headers: headers,
      background: background,
      label: label,
    );
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
