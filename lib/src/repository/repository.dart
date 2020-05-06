part of flutter_data;

abstract class Repository<T extends DataSupportMixin<T>> {
  Repository(this.manager, {bool remote, bool verbose})
      : _remote = remote ?? true,
        _verbose = verbose ?? true;

  final bool _remote;
  final bool _verbose;

  @protected
  final DataManager manager;

  //

  String get type;

  String get baseUrl;

  String urlForFindAll(params);
  DataRequestMethod methodForFindAll(params);

  String urlForFindOne(id, params);
  DataRequestMethod methodForFindOne(id, params);

  String urlForSave(id, params);
  DataRequestMethod methodForSave(id, params);

  String urlForDelete(id, params);
  DataRequestMethod methodForDelete(id, params);

  Map<String, dynamic> get params => {};
  Map<String, dynamic> get headers => {};

  // metadata

  Repository repositoryFor(String type);

  // serialization

  Map<String, dynamic> serialize(T model);

  Iterable<Map<String, dynamic>> serializeCollection(Iterable<T> models);

  T deserialize(dynamic object, {String key, bool initialize = true});

  Iterable<T> deserializeCollection(object);

  // repository methods

  Future<List<T>> findAll(
      {bool remote, Map<String, dynamic> params, Map<String, dynamic> headers});

  DataStateNotifier<List<T>> watchAll(
      {bool remote, Map<String, dynamic> params, Map<String, dynamic> headers});

  Future<T> findOne(dynamic id,
      {bool remote, Map<String, dynamic> params, Map<String, dynamic> headers});

  DataStateNotifier<T> watchOne(dynamic id,
      {bool remote,
      Map<String, dynamic> params,
      Map<String, dynamic> headers,
      WithRelationships andAlso});

  Future<T> save(T model,
      {bool remote, Map<String, dynamic> params, Map<String, dynamic> headers});

  Future<void> delete(dynamic id,
      {bool remote, Map<String, dynamic> params, Map<String, dynamic> headers});

  Map<dynamic, T> dumpLocal();

  //

  T _init(T model, {String key, bool save = false});

  void syncRelationships(T model);

  @mustCallSuper
  Future<void> dispose();
}
