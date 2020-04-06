part of flutter_data;

class BelongsTo<E extends DataSupportMixin<E>> extends Relationship<E> {
  @protected
  @visibleForTesting
  DataId<E> dataId;

  BelongsTo._(this.dataId, [DataManager manager]) {
    super._manager = manager;
  }

  BelongsTo([E model, DataManager manager])
      : this._(model != null ? manager.dataId<E>(model.id, model: model) : null,
            manager);

  // serialization constructors

  factory BelongsTo.fromJson(Map<String, dynamic> map) {
    final key = map['_'][0] as String;
    final manager = map['_'][1] as DataManager;
    return BelongsTo._(
        key != null ? DataId.byKey(key, manager) : null, manager);
  }

  // end constructors

  set owner(DataId owner) {
    _owner = owner;
    _manager = owner.manager;
    if (dataId != null) {
      // if a "temporary" model is associated to the dataId, initialize
      dataId.model?._init(_repository);
      // trigger re-run DataId
      dataId = _manager.dataId<E>(dataId.id);
    }
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
    dataId = _manager.dataId<E>(value.id);
  }

  String get key => dataId?.key;

  @override
  String toString() => 'BelongsTo<$E>(${dataId.id})';

  @override
  bool operator ==(dynamic other) =>
      identical(this, other) || dataId == other.dataId;

  @override
  int get hashCode => runtimeType.hashCode ^ dataId.hashCode;
}
