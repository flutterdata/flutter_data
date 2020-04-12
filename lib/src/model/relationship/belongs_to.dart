part of flutter_data;

class BelongsTo<E extends DataSupportMixin<E>> extends Relationship<E> {
  @protected
  @visibleForTesting
  DataId<E> dataId;
  E _uninitializedModel;
  final bool _saveLocal;

  BelongsTo([E model, DataManager manager, this._saveLocal = true])
      : _uninitializedModel = model,
        super(manager) {
    initializeModel();
  }

  BelongsTo._(this.dataId, DataManager manager)
      : _saveLocal = true,
        super(manager);

  factory BelongsTo.fromJson(Map<String, dynamic> map) {
    final key = map['_'][0] as String;
    final manager = map['_'][1] as DataManager;
    return BelongsTo._(
        key != null ? DataId.byKey(key, manager) : null, manager);
  }

  // ownership & init

  initializeModel() {
    if (_manager != null && _uninitializedModel != null) {
      value = _uninitializedModel;
      _uninitializedModel = null;
    }
  }

  set owner(DataId owner) {
    _owner = owner;
    _manager = owner.manager;
    initializeModel();
  }

  set inverse(DataId<E> inverse) {
    dataId = inverse;
  }

  //

  E get value {
    final value = _repository.localAdapter.findOne(dataId?.key);
    if (value != null) {
      _repository.setInverseInModel(_owner, value);
    }
    return value;
  }

  set value(E value) {
    dataId = value?._init(_repository, saveLocal: _saveLocal)?.dataId;
  }

  String get key => dataId?.key;

  @override
  bool operator ==(dynamic other) =>
      identical(this, other) || dataId == other.dataId;

  @override
  int get hashCode => runtimeType.hashCode ^ dataId.hashCode;

  @override
  toJson() => key;

  @override
  String toString() => 'BelongsTo<$E>(${dataId?.id})';
}
