import 'package:flutter_data/flutter_data.dart';

mixin StandardJSONAdapter<T extends DataSupportMixin<T>> on Repository<T> {
  @override
  Map<String, dynamic> get headers =>
      super.headers..addAll({'Content-Type': 'application/json'});

  String get identifier => 'id';
  String get identifierSuffix => '_id';

  // Transforms a class into standard JSON
  @override
  Map<String, dynamic> serialize(T model) {
    final map = super.serialize(model);

    final relationships = <String, dynamic>{};

    for (var relEntry in relationshipMetadata['HasMany'].entries) {
      final name = relEntry.key.toString();
      final keys = List<String>.from(map[name] as Iterable);
      final type = relEntry.value;
      relationships[name] = DataId.byKeys(keys, manager, type: type.toString())
          .map((dataId) => dataId.id)
          .toList();
      map.remove(name);
    }

    for (var relEntry in relationshipMetadata['BelongsTo'].entries) {
      final k = '${relEntry.key}';
      final ks = '$k$identifierSuffix';

      final key = map[k].toString();
      final type = relEntry.value;
      relationships[ks] = DataId.byKey(key, manager, type: type.toString())?.id;
      map.remove(k);
    }

    final json = map;
    json.addAll(relationships);

    return json;
  }

  // Transforms standard JSON into a class
  @override
  T deserialize(object, {String key, bool initialize = true}) {
    final map = object as Map<String, dynamic>;

    for (var relEntry in relationshipMetadata['HasMany'].entries) {
      final k = '${relEntry.key}';
      if (map[k] != null) {
        map[k] = map[k].map((i) {
          final type = relEntry.value.toString();
          if (i is Map) {
            final repo = repositoryFor(type);
            final model = repo.deserialize(i);
            i = model.id;
          }
          final dataId = manager.dataId(i.toString(), type: type);
          return dataId.key;
        }).toList();
      }
    }

    for (var relEntry in relationshipMetadata['BelongsTo'].entries) {
      final k = '${relEntry.key}';
      final ks = '$k$identifierSuffix';

      final type = relEntry.value.toString();
      if (map[k] is Map) {
        final repo = repositoryFor(type);
        final model = repo.deserialize(map[k]);
        map[k] = model.id;
      } else if (map[ks] != null) {
        map[k] = map[ks].toString();
        map.remove(ks);
      }

      final dataId = manager.dataId(map[k]?.toString(), type: type);
      map[k] = dataId.key;
    }

    return super.deserialize(map, key: key, initialize: initialize);
  }
}
