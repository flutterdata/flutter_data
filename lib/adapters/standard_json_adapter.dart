import 'package:flutter_data/flutter_data.dart';

mixin StandardJSONAdapter<T extends DataSupportMixin<T>> on RemoteAdapter<T> {
  @override
  Map<String, String> get headers =>
      super.headers..addAll({'Content-Type': 'application/json'});

  String get identifierSuffix => '_id';

  @override
  String keyForField(String field) {
    final belongsToFields =
        (relationshipMetadata['BelongsTo'] as Map<String, String>).keys;
    if (belongsToFields.contains(field)) {
      return '$field$identifierSuffix';
    }
    return super.keyForField(field);
  }

  @override
  String fieldForKey(String key) {
    if (key.endsWith(identifierSuffix)) {
      final keyWithoutId = key.substring(0, key.length - 3);
      final belongsToFields =
          (relationshipMetadata['BelongsTo'] as Map<String, String>).keys;
      if (belongsToFields.contains(keyWithoutId)) {
        return keyWithoutId;
      }
    }
    return super.fieldForKey(key);
  }

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
      final field = '${relEntry.key}';
      final key = keyForField(field);

      final dataIdKey = map[field].toString();
      final type = relEntry.value;
      relationships[key] =
          DataId.byKey(dataIdKey, manager, type: type.toString())?.id;
      map.remove(field);
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
            final repo = repositoryFor(type) as RemoteAdapter;
            final model = repo.deserialize(i);
            i = model.id;
          }
          final dataId = manager.dataId(i.toString(), type: type);
          return dataId.key;
        }).toList();
      }
    }

    for (var relEntry in relationshipMetadata['BelongsTo'].entries) {
      final field = '${relEntry.key}';
      final _key = keyForField(field);

      final type = relEntry.value.toString();
      if (map[field] is Map) {
        final repo = repositoryFor(type) as RemoteAdapter;
        final model = repo.deserialize(map[field]);
        map[field] = model.id;
      } else if (map[_key] != null) {
        map[field] = map[_key].toString();
        map.remove(_key);
      }

      final dataId = manager.dataId(map[field]?.toString(), type: type);
      map[field] = dataId.key;
    }

    return super.deserialize(map, key: key, initialize: initialize);
  }
}
