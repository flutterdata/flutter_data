part of flutter_data;

/// A mixin to "tag" and ensure the implementation of an [id] getter
/// in data classes managed through Flutter Data.
///
/// It contains private state and methods to track the model's identity.
abstract class DataModel<T extends DataModel<T>> {
  Object get id;

  // "late" finals
  String _key;
  Map<String, RemoteAdapter> _adapters;

  // computed
  String get _type => DataHelpers.getType<T>();
  RemoteAdapter<T> get _adapter => _adapters[_type] as RemoteAdapter<T>;
  bool get _isInitialized => _key != null && _adapters != null;

  // initializers

  T _initialize(final Map<String, RemoteAdapter> adapters,
      {final String key, final bool save = false}) {
    if (_isInitialized) return _this;

    _this._adapters = adapters;

    assert(_adapter != null, '''\n
Please ensure `Repository<$T>` has been correctly initialized.\n
''');

    _this._key = _adapter.graph.getKeyForId(_this._adapter.type, _this.id,
        keyIfAbsent: key ?? DataHelpers.generateKey<T>());

    if (save) {
      _adapter.localAdapter.save(_this._key, _this);
    }

    // initialize relationships
    for (final metadata
        in _adapter.localAdapter.relationshipsFor(_this).entries) {
      final relationship = metadata.value['instance'] as Relationship;

      relationship?.initialize(
        adapters: adapters,
        owner: _this,
        name: metadata.key,
        inverseName: metadata.value['inverse'] as String,
      );
    }

    return _this;
  }
}

/// Extension that adds syntax-sugar to data classes,
/// linking them to common [Repository] methods such as
/// [save] and [delete].
extension DataModelExtension<T extends DataModel<T>> on DataModel<T> {
  T get _this => this as T;

  /// Initializes a model copying the identity of supplied [model].
  ///
  /// Usage:
  /// ```
  /// final post = await repository.findOne('1'); // returns initialized post
  /// final newPost = Post(title: 'test'); // uninitialized post
  /// newPost.was(post); // new is now initialized with same key as post
  /// ```
  T was(T model) {
    assert(model != null && model._isInitialized,
        'Please initialize model before passing it to `was`');
    return _this._initialize(model._adapters, key: model._key, save: true);
  }

  /// Saves this model through a call equivalent to [Repository.save].
  ///
  /// Usage: `await post.save()`, `author.save(remote: false, params: {'a': 'x'})`.
  ///
  /// **Requires this model to be initialized.**
  Future<T> save(
      {bool remote,
      Map<String, dynamic> params,
      Map<String, String> headers}) async {
    _assertInit('save');
    return await _adapter.save(_this,
        remote: remote, params: params, headers: headers, init: true);
  }

  /// Deletes this model through a call equivalent to [Repository.delete].
  ///
  /// Usage: `await post.delete()`
  ///
  /// **Requires this model to be initialized.**
  Future<void> delete(
      {bool remote,
      Map<String, dynamic> params,
      Map<String, String> headers}) async {
    _assertInit('delete');
    await _adapter.delete(_this,
        remote: remote, params: params, headers: headers);
  }

  /// Re-fetch this model through a call equivalent to [Repository.findOne].
  /// with the current object/[id]
  ///
  /// **Requires this model to be initialized.**
  Future<T> reload(
      {bool remote,
      Map<String, dynamic> params,
      Map<String, String> headers}) async {
    _assertInit('reload');
    return await _adapter.findOne(_this,
        remote: remote, params: params, headers: headers, init: true);
  }

  /// Watch this model through a call equivalent to [Repository.watchOne].
  /// with the current object/[id].
  ///
  /// **Requires this model to be initialized.**
  DataStateNotifier<T> watch(
      {bool remote,
      Map<String, dynamic> params,
      Map<String, String> headers,
      AlsoWatch<T> alsoWatch}) {
    _assertInit('watch');
    return _adapter.watchOne(_this,
        remote: remote, params: params, headers: headers, alsoWatch: alsoWatch);
  }

  void _assertInit(String method) {
    assert(_isInitialized, '''\n
This model MUST be initialized in order to call `$method`.

DON'T DO THIS:

  final ${_type.singularize()} = $T(...);
  ${_type.singularize()}.$method(...);

DO THIS:

  final ${_type.singularize()} = $T(...).init(context);
  ${_type.singularize()}.$method(...);

Call `init(context)` on the model first.

This ONLY happens when a model is manually instantiated
and had no contact with Flutter Data.

Initializing models is not necessary in any other case.

When assigning new models to a relationship, only initialize
the actual model:

Family(surname: 'Carlson', dogs: {Dog(name: 'Jerry'), Dog(name: 'Zoe')}.asHasMany).init(context);
''');
  }
}

/// Returns a model's `_key` private attribute.
///
/// Useful for testing, debugging or usage in [RemoteAdapter] subclasses.
String keyFor<T extends DataModel<T>>(T model) => model?._key;
