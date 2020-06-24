part of flutter_data;

class BelongsTo<E extends DataSupport<E>> extends Relationship<E, E> {
  BelongsTo([E model, DataManager manager])
      : super(model != null ? {model} : null, manager);

  BelongsTo._(String key, DataManager manager, bool _wasOmitted)
      : super._(key != null ? {key} : {}, manager, _wasOmitted);

  factory BelongsTo.fromJson(Map<String, dynamic> map) {
    final key = map['_'][0] as String;
    final manager = map['_'][2] as DataManager;
    if (key == null) {
      final wasOmitted = map['_'][1] as bool;
      return BelongsTo._(null, manager, wasOmitted);
    }
    return BelongsTo._(key, manager, false);
  }

  //

  E get value {
    return super.isNotEmpty ? super.first : null;
  }

  set value(E value) {
    if (value != null) {
      if (super.isNotEmpty) {
        super.remove(this.value);
      }
      super.add(value);
    } else {
      super.remove(this.value);
    }
    assert(length <= 1);
  }

  @protected
  @visibleForTesting
  String get key => super.keys.isNotEmpty ? super.keys.first : null;

  //

  @override
  ValueStateNotifier<E> watch() {
    _notifier ??= ValueStateNotifier();
    _graphEvents.forEach((events) {
      if (events.isNotEmpty) {
        _notifier.value =
            events.last.type == DataGraphEventType.removeNode ? null : value;
      }
    });
    return _notifier;
  }

  //

  @override
  dynamic toJson() => key;

  @override
  String toString() => 'BelongsTo<$E>(${key ?? ''})';
}
