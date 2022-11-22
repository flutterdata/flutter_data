part of flutter_data;

/// Data classes extending this class are marked to be managed
/// through Flutter Data.
///
/// It enforces the implementation of an [id] getter.
/// It contains private state and methods to track the model's identity.
abstract class DataModel<T extends DataModel<T>> {
  Object? get id;

  DataModel() {
    final repository = internalRepositories[_internalType];
    if (repository != null) {
      repository.remoteAdapter.localAdapter.initModel(
        this,
        onModelInitialized: repository.remoteAdapter.onModelInitialized,
      );
    }
  }

  String? _key;
  String get _internalType => DataHelpers.getInternalType<T>();
  T get _this => this as T;

  /// Exposes this type's [RemoteAdapter]
  RemoteAdapter<T> get _remoteAdapter =>
      internalRepositories[_internalType]!.remoteAdapter as RemoteAdapter<T>;

  // data model helpers

  /// Returns a model's `_key` private attribute.
  ///
  /// Useful for testing, debugging or usage in [RemoteAdapter] subclasses.
  static String keyFor(DataModel model) => model._key!;

  /// Returns a model's non-null relationships.
  static Map<String, Relationship> relationshipsFor<T extends DataModel<T>>(
      T model) {
    return {
      for (final meta
          in model._remoteAdapter.localAdapter.relationshipMetas.values)
        if (meta.instance(model) != null) meta.name: meta.instance(model)!,
    };
  }

  /// Returns a model [RemoteAdapter]
  static RemoteAdapter adapterFor(DataModel model) => model._remoteAdapter;

  /// Apply [model]'s key to [applyTo].
  static DataModel withKeyOf(DataModel model, {required DataModel applyTo}) {
    final _this = applyTo;
    if (model._key != _this._key) {
      DataModel oldModel = _this;
      DataModel newModel = model;

      final oldKey = oldModel._key;
      if (_this._key != newModel._key) {
        _this._key = newModel._key;
      }
      if (_this._key != oldModel._key) {
        oldModel._key = _this._key;
        _this._remoteAdapter.graph.removeKey(oldKey!);
      }

      if (oldModel.id != null) {
        _this._remoteAdapter.graph
            .removeId(_this._internalType, oldModel.id!, notify: false);
        _this._remoteAdapter.graph.getKeyForId(_this._internalType, oldModel.id,
            keyIfAbsent: _this._key);
      }
    }
    return _this;
  }
}

/// Extension that adds syntax-sugar to data classes,
/// linking them to common [Repository] methods such as
/// [save] and [delete].
extension DataModelExtension<T extends DataModel<T>> on DataModel<T> {
  /// Copy identity (internal key) from an old model to a new one
  /// to signal they are the same.
  ///
  /// **Only makes sense to use if model is immutable and has no ID!**
  ///
  /// ```
  /// final walter = Person(name: 'Walter');
  /// person.copyWith(age: 56).withKeyOf(walter);
  /// ```
  ///
  /// [force] will set [model]'s key even if its `id` is null.
  T withKeyOf(T model, {bool force = false}) {
    return DataModel.withKeyOf(model, applyTo: this) as T;
  }

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
    return await _remoteAdapter.save(
      _this,
      remote: remote,
      params: params,
      headers: headers,
      onSuccess: onSuccess,
      onError: onError,
    );
  }

  /// Deletes this model through a call equivalent to [Repository.delete].
  Future<T?> delete({
    bool? remote,
    Map<String, dynamic>? params,
    Map<String, String>? headers,
    OnSuccessOne<T>? onSuccess,
    OnErrorOne<T>? onError,
  }) async {
    return await _remoteAdapter.delete(
      this,
      remote: remote,
      params: params,
      headers: headers,
      onSuccess: onSuccess,
      onError: onError,
    );
  }

  /// Reload this model through a call equivalent to [Repository.findOne].
  /// with the current object/[id]
  Future<T?> reload({
    bool? remote,
    Map<String, dynamic>? params,
    Map<String, String>? headers,
    bool? background,
    DataRequestLabel? label,
  }) async {
    return await _remoteAdapter.findOne(
      this,
      remote: remote,
      params: params,
      headers: headers,
      background: background,
      label: label,
    );
  }

  // locals

  /// Saves this model to local storage.
  T saveLocal() => _remoteAdapter.saveLocal(_this);

  /// Deletes this model from local storage.
  void deleteLocal() => _remoteAdapter.deleteLocal(_this);

  /// Reload model from local storage.
  T? reloadLocal() => _remoteAdapter.localAdapter.findOne(_key);
}
