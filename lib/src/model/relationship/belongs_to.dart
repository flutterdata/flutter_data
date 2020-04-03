part of flutter_data;

class BelongsTo<E extends DataSupport<E>> extends Relationship<E> {
  @protected
  @visibleForTesting
  DataId<E> dataId;

  BelongsTo._(this.dataId,
      [DataManager manager, List<ResourceObject> included]) {
    super._manager = manager;
    _saveIncluded(included, [dataId]);
  }

  BelongsTo([E model, DataManager manager])
      : this._(model != null ? manager.dataId<E>(model.id, model: model) : null,
            manager);

  // serialization constructors

  factory BelongsTo.fromToOne(dynamic rel, DataManager manager,
      {List<ResourceObject> included}) {
    if (rel == null) {
      return BelongsTo<E>._(null, manager);
    }
    return BelongsTo._(
      manager.dataId<E>((rel as ToOne).linkage.id),
      manager,
      included,
    );
  }

  factory BelongsTo.fromKey(dynamic key, DataManager manager) =>
      BelongsTo._(DataId.byKey<E>(key.toString(), manager), manager);

  factory BelongsTo.fromJson(Map<String, dynamic> map) {
    return map['BelongsTo'] as BelongsTo<E>;
  }

  // end constructors

  set owner(DataId owner) {
    _owner = owner;
    _manager = owner.manager;
    if (dataId != null) {
      dataId.model?._init(_repository);
      // trigger re-run DataId
      dataId = _manager.dataId<E>(dataId.id);
    }
  }

  E get value => _box.get(key);

  set value(E value) {
    dataId = _manager.dataId<E>(value.id);
    _repository.setOwnerInModel(_owner, value);
  }

  String get key => dataId?.key;

  ToOne get toOne => dataId != null ? ToOne(dataId.identifierObject) : null;

  @override
  Map<String, dynamic> toJson() => toOne?.linkage?.toJson();

  @override
  String toString() => 'BelongsTo<$E>(${dataId.id})';

  @override
  bool operator ==(dynamic other) =>
      identical(this, other) || dataId == other.dataId;

  @override
  int get hashCode => runtimeType.hashCode ^ dataId.hashCode;
}
