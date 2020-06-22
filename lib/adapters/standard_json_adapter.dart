import 'package:flutter_data/flutter_data.dart';

mixin StandardJSONAdapter<T extends DataSupport<T>> on RemoteAdapter<T> {
  @override
  Map<String, String> get headers =>
      super.headers..addAll({'Content-Type': 'application/json'});

  Map<String, Map<String, Object>> get belongsTos => Map.fromEntries(
      relationshipsFor().entries.where((e) => e.value['kind'] == 'BelongsTo'));

  Map<String, Map<String, Object>> get hasManys => Map.fromEntries(
      relationshipsFor().entries.where((e) => e.value['kind'] == 'HasMany'));

  String get identifierSuffix => '_id';

  @override
  String keyForField(String field) {
    if (belongsTos.keys.contains(field)) {
      return '$field$identifierSuffix';
    }
    return super.keyForField(field);
  }

  @override
  String fieldForKey(String key) {
    if (key.endsWith(identifierSuffix)) {
      final keyWithoutId = key.substring(0, key.length - 3);
      if (belongsTos.keys.contains(keyWithoutId)) {
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

    for (var relEntry in hasManys.entries) {
      final name = relEntry.key.toString();
      final keys = List<String>.from(map[name] as Iterable);
      relationships[name] = keys.map(manager.getId);
      map.remove(name);
    }

    for (var relEntry in belongsTos.entries) {
      final field = '${relEntry.key}';
      final key = keyForField(field);

      final dataIdKey = map[field].toString();
      relationships[key] = manager.getId(dataIdKey);
      map.remove(field);
    }

    final json = map;
    json.addAll(relationships);

    return json;
  }

  // Transforms standard JSON into a class
  @override
  T deserialize(object, {String key}) {
    final map = object as Map<String, dynamic>;

    for (var relEntry in hasManys.entries) {
      final k = '${relEntry.key}';
      if (map[k] != null) {
        map[k] = map[k].map((i) {
          final type = relEntry.value['type'] as String;
          if (i is Map) {
            final repo = relatedRepositories[type] as RemoteAdapter;
            final model = repo.deserialize(i);
            i = model.id;
          }
          return manager.getKeyForId(type, i,
              keyIfAbsent: Repository.generateKey(type));
        }).toList();
      }
    }

    for (var relEntry in belongsTos.entries) {
      final field = '${relEntry.key}';
      final _key = keyForField(field);

      final type = relEntry.value['type'] as String;
      if (map[field] is Map) {
        final repo = relatedRepositories[type] as RemoteAdapter;
        final model = repo.deserialize(map[field]);
        map[field] = model.id;
      } else if (map[_key] != null) {
        map[field] = map[_key].toString();
        map.remove(_key);
      }

      if (map[field] != null) {
        map[field] = manager.getKeyForId(type, map[field],
            keyIfAbsent: Repository.generateKey(type));
      }
    }

    return super.deserialize(map, key: key);
  }
}
