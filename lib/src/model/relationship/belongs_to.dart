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
      : this._(
            model != null ? DataId<E>(model.id, manager, model: model) : null,
            manager);

  // serialization constructors

  factory BelongsTo.fromToOne(dynamic toOne, DataManager manager,
      {List<ResourceObject> included}) {
    if (toOne == null) return BelongsTo<E>._(null, manager);
    return BelongsTo._(
      DataId<E>((toOne as ToOne).linkage.id, manager),
      manager,
      included,
    );
  }

  factory BelongsTo.fromKey(key, DataManager manager) =>
      BelongsTo._(DataId.byKey<E>(key.toString(), manager), manager);

  factory BelongsTo.fromJson(Map<String, dynamic> map) {
    return map['BelongsTo'] as BelongsTo<E>;
  }

  // end constructors

  set owner(DataId owner) {
    _owner = owner;
    _manager = owner.manager;
    if (dataId != null) {
      if (dataId.model != null) {
        _manager.locator<Repository<E>>().create(dataId.model);
      }
      // trigger re-run DataId
      dataId = DataId<E>(dataId.id, _manager);
    }
  }

  E get value => _box.get(key);

  set value(E value) {
    dataId = DataId<E>(value.id, _manager);
    _repository.setOwnerInModel(_owner, value);
  }

  String get key => dataId?.key;

  ToOne get toOne => ToOne(dataId);

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
