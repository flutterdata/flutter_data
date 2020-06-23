import 'package:flutter_data/flutter_data.dart';
import 'package:json_api/document.dart';
import 'package:json_api/document.dart' as j show Relationship;

mixin JSONAPIAdapter<T extends DataSupport<T>> on RemoteAdapter<T> {
  @override
  Map<String, String> get headers => super.headers
    ..addAll({
      'Content-Type': 'application/vnd.api+json',
      'Accept': 'application/vnd.api+json',
    });

  Map<String, Map<String, Object>> get belongsTos => Map.fromEntries(
      relationshipsFor().entries.where((e) => e.value['kind'] == 'BelongsTo'));

  Map<String, Map<String, Object>> get hasManys => Map.fromEntries(
      relationshipsFor().entries.where((e) => e.value['kind'] == 'HasMany'));

  // Transforms native format into JSON:API
  @override
  Map<String, dynamic> serialize(model) {
    final map = super.serialize(model);

    final relationships = <String, j.Relationship>{};

    for (final relEntry in hasManys.entries) {
      final name = relEntry.key.toString();
      if (map[name] != null) {
        final keys = List<String>.from(map[name] as Iterable);
        final relType = relEntry.value['type'] as String;
        final identifiers = keys.map((key) {
          return IdentifierObject(relType, manager.getId(key));
        });
        relationships[name] = ToMany(identifiers);
        map.remove(name);
      }
    }

    for (final relEntry in belongsTos.entries) {
      final name = relEntry.key.toString();
      if (map[name] != null) {
        final key = map[name].toString();
        final relType = relEntry.value['type'] as String;
        relationships[name] =
            ToOne(IdentifierObject(relType, manager.getId(key)));
        map.remove(name);
      }
    }

    final id = map.remove('id');
    final resource = ResourceObject(type, id.toString(),
        attributes: map, relationships: relationships);

    return Document(ResourceData(resource)).toJson();
  }

  @override
  Iterable<T> deserializeCollection(object) {
    final doc = Document.fromJson(object, ResourceCollectionData.fromJson);
    _saveIncluded(doc.data.included);
    return super.deserializeCollection(doc.data.collection);
  }

  // Transforms JSON:API into native format
  @override
  T deserialize(object, {String key}) {
    final nativeMap = <String, dynamic>{};
    final included = <ResourceObject>[];
    ResourceObject obj;

    if (object is ResourceObject) {
      obj = object;
    } else {
      final doc = Document.fromJson(object, ResourceData.fromJson);
      obj = doc.data.resourceObject;
      if (doc.data.included != null) {
        included.addAll(doc.data.included);
      }
    }

    // save included first (get keys for them before the relationships)
    _saveIncluded(included);

    nativeMap['id'] = obj.id;

    if (obj.relationships != null) {
      for (var relEntry in obj.relationships.entries) {
        final rel = relEntry.value;
        if (rel is ToOne && rel.linkage != null) {
          final key = manager.getKeyForId(rel.linkage.type, rel.linkage.id,
              keyIfAbsent: Repository.generateKey(rel.linkage.type));
          nativeMap[relEntry.key] = key;
        } else if (rel is ToMany) {
          nativeMap[relEntry.key] = rel.linkage
              .map((i) => manager.getKeyForId(i.type, i.id,
                  keyIfAbsent: Repository.generateKey(i.type)))
              .toList();
        }
      }
    }

    nativeMap.addAll(obj.attributes);

    return super.deserialize(nativeMap, key: key);
  }

  void _saveIncluded(List<ResourceObject> included) {
    included ??= const [];
    for (var i in included) {
      final key = manager.getKeyForId(i.type, i.id);
      final type = Repository.getType(i.type);
      final repo = relatedRepositories[type] as RemoteAdapter;
      repo?.deserialize(i, key: key);
    }
  }
}
