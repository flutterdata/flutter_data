part of flutter_data;

class HasMany<E extends DataSupport<E>> extends Relationship<E, Set<E>> {
  HasMany([Set<E> models]) : super(models);

  HasMany._(Iterable<String> keys, bool _wasOmitted)
      : super._(keys, _wasOmitted);

  factory HasMany.fromJson(Map<String, dynamic> map) {
    if (map['_'][0] == null) {
      final wasOmitted = map['_'][1] as bool;
      return HasMany._({}, wasOmitted);
    }
    final keys = <String>{...map['_'][0]};
    return HasMany._(keys, false);
  }

  // notifier

  ValueStateNotifier<Set<E>> _notifier;

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

  // misc

  @override
  dynamic toJson() => keys.toImmutableList();

  @override
  String toString() => 'HasMany<$E>($keys)';
}
