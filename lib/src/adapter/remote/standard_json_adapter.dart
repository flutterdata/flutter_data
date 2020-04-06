import 'package:flutter_data/flutter_data.dart';
import 'package:recase/recase.dart';

mixin StandardJSONAdapter<T extends DataSupport<T>> on RemoteAdapter<T> {
  @override
  get headers => super.headers..addAll({'Content-Type': 'application/json'});

  String get identifier => 'id';
  String get identifierSuffix => '_id';

  // String serializeKey(String key) => ReCase(key).snakeCase;
  // String deserializeKey(String key) => ReCase(key).camelCase;

  // var belongsToKey =
  //         entry.key.replaceFirst(RegExp('$identifierSuffix\\b'), "");

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
          .map((dataId) => dataId.id);
      map.remove(name);
    }

    for (var relEntry in relationshipMetadata['BelongsTo'].entries) {
      final name = '${relEntry.key}$identifierSuffix';
      final key = map[name].toString();
      final type = relEntry.value;
      relationships[name] =
          DataId.byKey(key, manager, type: type.toString()).id;
      map.remove(name);
    }

    final json = map;
    json.addAll(relationships);

    return json;
  }

  // Transforms standard JSON into a class
  @override
  T deserialize(object, {key}) {
    final obj = object as Map<String, dynamic>;

    for (var relEntry in relationshipMetadata['HasMany'].entries) {
      final k = relEntry.key.toString();
      obj[k] = obj[k].map((i) {
        final type = relEntry.value.toString();
        if (i is Map) {
          final repo = relationshipMetadata['repository#$type'] as Repository;
          final model = repo.deserialize(i);
          i = model.id;
        }
        final dataId = manager.dataId(i.toString(), type: type);
        return dataId.key;
      }).toList();
    }

    for (var relEntry in relationshipMetadata['BelongsTo'].entries) {
      final k = relEntry.key.toString();
      final type = relEntry.value.toString();
      if (obj[k] is Map) {
        final repo = relationshipMetadata['repository#$type'] as Repository;
        final model = repo.deserialize(obj[k]);
        obj[k] = model.id;
      }

      final dataId = manager.dataId(obj[k].toString(), type: type);
      obj[k] = dataId.key;
    }

    return super.deserialize(obj);
  }
}
