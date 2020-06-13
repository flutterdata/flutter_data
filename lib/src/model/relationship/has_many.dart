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
    manager.graph.where((event) {
      return event.keys.any((k) => keys.contains(k));
    }).forEach((_) => _notifier.value = this);
    return _notifier;
  }

  //

  @override
  dynamic toJson() => keys.toList();

  @override
  String toString() => 'HasMany<$E>($keys)';
}
