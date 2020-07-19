part of flutter_data;

class BelongsTo<E extends DataSupport<E>> extends Relationship<E, E> {
  BelongsTo([final E model]) : super(model != null ? {model} : null);

  BelongsTo._(String key, bool _wasOmitted)
      : super._(key != null ? {key} : {}, _wasOmitted);

  factory BelongsTo.fromJson(final Map<String, dynamic> map) {
    final key = map['_'][0] as String;
    if (key == null) {
      final wasOmitted = map['_'][1] as bool;
      return BelongsTo._(null, wasOmitted);
    }
    return BelongsTo._(key, false);
  }

  /// Specific methods for [BelongsTo]

  E get value => safeFirst;

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
  String get key => super.keys.safeFirst;

  // notifier

  @override
  StateNotifier<E> watch() {
    return _graphEvents.where((e) => e.isNotEmpty).map((e) {
      return e.last.type == DataGraphEventType.removeNode ? null : value;
    });
  }

  // misc

  @override
  dynamic toJson() => key;

  @override
  String toString() => 'BelongsTo<$E>(${key ?? ''})';
}
