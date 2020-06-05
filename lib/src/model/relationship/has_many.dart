part of flutter_data;

class HasMany<E extends DataSupportMixin<E>> extends Relationship<E, Set<E>> {
  HasMany([Set<E> models, DataManager manager, bool _save])
      : super(models, manager, _save);

  HasMany._(Iterable<String> keys, DataManager manager, bool _wasOmitted)
      : super._(keys, manager, _wasOmitted);

  factory HasMany.fromJson(Map<String, dynamic> map) {
    final manager = map['_'][2] as DataManager;
    if (map['_'][0] == null) {
      final wasOmitted = map['_'][1] as bool;
      return HasMany._({}, manager, wasOmitted);
    }
    final keys = List<String>.from(map['_'][0] as Iterable);
    return HasMany._(keys, manager, false);
  }

  //

  @override
  ValueStateNotifier<Set<E>> watch() {
    _notifier ??= ValueStateNotifier();
    _graphNotifier.where((event) {
      // this filter could be improved, but for now:
      if (event.type == GraphEventType.removed) {
        // (removed) event.keys has _ownerKey and at least one key of this type
        return event.keys.contains(_ownerKey) &&
            event.keys.where((key) => key.startsWith(type)).isNotEmpty;
      } else {
        // (added) event.keys contains at least one of our keys
        return event.keys.toSet().intersection(keys).isNotEmpty;
      }
    }).forEach((event) {
      _notifier.value = this;
    });
    return _notifier;
  }

  //

  @override
  dynamic toJson() => keys.toList();

  @override
  String toString() => 'HasMany<$E>($keys)';
}
