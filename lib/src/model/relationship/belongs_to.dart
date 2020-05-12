part of flutter_data;

class BelongsTo<E extends DataSupportMixin<E>> extends Relationship<E> {
  @protected
  @visibleForTesting
  DataId<E> dataId;
  E _uninitializedModel;
  final bool _save;
  DataStateNotifier<E> _notifier;

  static const oneFrameDuration = Duration(milliseconds: 16);

  BelongsTo([E model, DataManager manager, this._save = true])
      : _uninitializedModel = model,
        super(manager) {
    initializeModel();
  }

  BelongsTo._(this.dataId, DataManager manager)
      : _save = true,
        super(manager);

  factory BelongsTo.fromJson(Map<String, dynamic> map) {
    final key = map['_'][0] as String;
    final manager = map['_'][1] as DataManager;
    return BelongsTo._(
        key != null ? DataId.byKey(key, manager) : null, manager);
  }

  // ownership & init

  void initializeModel() {
    if (_repository != null && _uninitializedModel != null) {
      value = _uninitializedModel;
      _uninitializedModel = null;
    }
  }

  set owner(DataId owner) {
    _owner = owner;
    manager = owner.manager;
    initializeModel();
  }

  set inverse(DataId<E> inverse) {
    dataId = inverse;
  }

  @override
  DataStateNotifier<E> watch() {
    // lazily initialize notifier
    return _notifier ??= _initNotifier();
  }

  //

  DataStateNotifier<E> _initNotifier() {
    _notifier = DataStateNotifier<E>(DataState());
    _repository.box
        .watch(key: key)
        .buffer(Stream.periodic(oneFrameDuration))
        .forEach((events) {
      if (events.isNotEmpty && events.last.deleted) {
        dataId = null;
      }
      _notifier.state = DataState(model: value);
    });
    return _notifier;
  }

  //

  E get value {
    final value = _repository?.box?.safeGet(dataId?.key) ?? _uninitializedModel;
    if (value != null) {
      _repository?.setInverseInModel(_owner, value);
    }
    return value;
  }

  set value(E value) {
    dataId = value != null
        ? _repository?.initModel(value, save: _save)?._dataId
        : null;
    _notifier?.state = DataState(model: value);
  }

  String get key => dataId?.key;

  @override
  dynamic toJson() => key;

  @override
  bool operator ==(dynamic other) =>
      identical(this, other) || dataId == other.dataId;

  @override
  int get hashCode => runtimeType.hashCode ^ dataId.hashCode;

  @override
  String toString() => 'BelongsTo<$E>(${dataId?.id})';
}
