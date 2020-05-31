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
  DataStateNotifier<Set<E>> watch() {
    // lazily initialize notifier
    return _notifier ??= _initNotifier();
  }

  DataStateNotifier<Set<E>> _initNotifier() {
    // REWRITE BASED ON GRAPH
    _notifier = DataStateNotifier<Set<E>>(DataState(model: {}));
    _repository.box
        .watch()
        .buffer(Stream.periodic(_repository.oneFrameDuration))
        .forEach((events) {
      final eventKeyMap = events.fold<Map<String, bool>>({}, (map, e) {
        map[e.key.toString()] = e.deleted;
        return map;
      });

      for (var entry in eventKeyMap.entries) {
        if (keys.contains(entry.key)) {
          if (entry.value) {
            // entry.value is bool deleted
            keys.removeWhere((key) => key == entry.key);
          }
          _notifier.state = DataState(model: this);
        }
      }
    });
    return _notifier;
  }

  //

  @override
  dynamic toJson() => keys.toList();

  @override
  String toString() => 'HasMany<$E>($keys)';
}
