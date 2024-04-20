part of flutter_data;

abstract class DataModel<T extends DataModel<T>> with DataModelMixin<T> {
  DataModel() {
    init();
  }

  /// Returns a model [Adapter]
  static Adapter adapterFor(DataModelMixin model) => model._adapter;

  // static T withKey<T extends DataModelMixin<T>>(String sourceKey,
  //     {required T applyTo}) {
  //   final core = applyTo._adapter.core;
  //   final type = applyTo._internalType;

  //   // ONLY data we keep from source is its key
  //   // ONLY data we remove from destination is its key
  //   if (sourceKey != applyTo._key) {
  //     final oldKey = applyTo._key;

  //     // assign correct key to destination
  //     applyTo._key = sourceKey;

  //     // migrate relationships to new key
  //     applyTo._adapter
  //         ._initializeRelationships(applyTo, fromKey: sourceKey);

  //     if (applyTo.id != null) {
  //       core._writeTxn(() {
  //         // and associate ID with source key
  //         // final typeId = applyTo.id!.typifyWith(type);
  //         // core._keyOperations.add(AddKeyOperation(sourceKey, typeId));

  //         if (oldKey != null) {
  //           core._storedModelBox.remove(oldKey.detypifyKey()!);
  //           // core._keyOperations.add(RemoveKeyOperation(oldKey));
  //         }
  //         // core._keyCache[sourceKey.detypify() as int] = typeId;
  //       });
  //     }
  //   }
  //   return applyTo;
  // }

  // data model helpers

  /// Returns a model's `_key` private attribute.
  ///
  /// Useful for testing, debugging or usage in [Adapter] subclasses.
  static String keyFor(DataModel model) {
    return model._key!;
  }
}

/// Data classes extending this class are marked to be managed
/// through Flutter Data.
///
/// It enforces the implementation of an [id] getter.
/// It contains private state and methods to track the model's identity.
mixin DataModelMixin<T extends DataModelMixin<T>> {
  Object? get id;
  String? _key;

  String get _internalType => DataHelpers.internalTypeFor(T.toString());
  T get _this => this as T;

  /// Exposes this type's [Adapter]
  Adapter<T> get _adapter => _internalAdapters![_internalType] as Adapter<T>;

  T init() {
    final adapter = _internalAdapters![_internalType];
    if (adapter != null) {
      adapter.initModel(
        this,
        onModelInitialized: adapter.onModelInitialized,
      );
    }
    return this as T;
  }

  static String? keyFor(DataModelMixin model) {
    return model._key;
  }

  /// Returns a model's non-null relationships.
  static Set<Relationship> relationshipsFor(DataModelMixin model) {
    return {
      for (final meta in model._adapter.relationshipMetas.values)
        if (meta.instance(model) != null) meta.instance(model)!,
    };
  }
}

/// Extension that adds syntax-sugar to data classes,
/// linking them to common [Adapter] methods such as
/// [save] and [delete].
extension DataModelExtension<T extends DataModelMixin<T>> on DataModelMixin<T> {
  /// Copy identity (internal key) from an old model to a new one
  /// to signal they are the same.
  ///
  /// **Only makes sense to use if model is immutable and has no ID!**
  ///
  /// ```
  /// final walter = Person(name: 'Walter');
  /// person.copyWith(age: 56).withKeyOf(walter);
  /// ```
  // T withKeyOf(T model) {
  //   if (model._key == null) {
  //     throw Exception("Model must be initialized:\n\n$model");
  //   }
  //   return DataModel.withKey<T>(model._key!, applyTo: this as T);
  // }

  /// Saves this model through a call equivalent to [save].
  ///
  /// Usage: `await post.save()`, `author.save(remote: false, params: {'a': 'x'})`.
  Future<T> save({
    bool remote = true,
    Map<String, dynamic>? params,
    Map<String, String>? headers,
    OnSuccessOne<T>? onSuccess,
    OnErrorOne<T>? onError,
  }) async {
    return await _adapter.save(
      _this,
      remote: remote,
      params: params,
      headers: headers,
      onSuccess: onSuccess,
      onError: onError,
    );
  }

  /// Deletes this model through a call equivalent to [Adapter.delete].
  Future<T?> delete({
    bool remote = true,
    Map<String, dynamic>? params,
    Map<String, String>? headers,
    OnSuccessOne<T>? onSuccess,
    OnErrorOne<T>? onError,
  }) async {
    return await _adapter.delete(
      this,
      remote: remote,
      params: params,
      headers: headers,
      onSuccess: onSuccess,
      onError: onError,
    );
  }

  /// Reload this model through a call equivalent to [Adapter.findOne].
  /// with the current object/[id]
  Future<T?> reload({
    bool remote = true,
    Map<String, dynamic>? params,
    Map<String, String>? headers,
    bool? background,
    DataRequestLabel? label,
  }) async {
    return await _adapter.findOne(
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
  T saveLocal() => _adapter.saveLocal(_this);

  /// Deletes this model from local storage.
  void deleteLocal() => _adapter.deleteLocal(_this);

  /// Reload model from local storage.
  T? reloadLocal() => _adapter.findOneLocal(_key);
}
