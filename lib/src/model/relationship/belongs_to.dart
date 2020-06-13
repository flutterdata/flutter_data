part of flutter_data;

class BelongsTo<E extends DataSupportMixin<E>> extends Relationship<E, E> {
  BelongsTo([E model, DataManager manager, bool _save])
      : super(model != null ? {model} : null, manager, _save);

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
        // remove to ensure there is only ONE key at most
        // do not notify as it's an "update" operation
        super._replace(super.first, value);
      } else {
        super.add(value);
      }
    } else {
      super.remove(this.value);
    }
  }

  @protected
  @visibleForTesting
  String get key => super.keys.isNotEmpty ? super.keys.first : null;

  //

  @override
  ValueStateNotifier<E> watch() {
    _notifier ??= ValueStateNotifier();
    manager.graph.where((event) {
      return event.keys.contains(key);
    }).forEach((event) {
      _notifier.value =
          event.type == DataGraphEventType.removeNode ? null : value;
    });
    return _notifier;
  }

  //

  @override
  dynamic toJson() => key;

  @override
  String toString() => 'BelongsTo<$E>(${key ?? ''})';
}
