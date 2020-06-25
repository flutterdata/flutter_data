part of flutter_data;

class HasMany<E extends DataSupport<E>> extends Relationship<E, Set<E>> {
  HasMany([Set<E> models, DataManager manager]) : super(models, manager);

  HasMany._(Iterable<String> keys, DataManager manager, bool _wasOmitted)
      : super._(keys, manager, _wasOmitted);

  factory HasMany.fromJson(Map<String, dynamic> map) {
    final manager = map['_'][2] as DataManager;
    if (map['_'][0] == null) {
      final wasOmitted = map['_'][1] as bool;
      return HasMany._({}, manager, wasOmitted);
    }
    final keys = <String>{...map['_'][0]};
    return HasMany._(keys, manager, false);
  }

  //

  @override
  ValueStateNotifier<Set<E>> watch() {
    _notifier ??= ValueStateNotifier();
    _graphEvents.forEach((events) {
      if (events.isNotEmpty) {
        _notifier.value = this;
      }
    });
    return _notifier;
  }

  //

  @override
  dynamic toJson() => keys.toImmutableList();

  @override
  String toString() => 'HasMany<$E>($keys)';
}
