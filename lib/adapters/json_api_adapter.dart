import 'package:flutter_data/flutter_data.dart';
import 'package:json_api/document.dart';
import 'package:json_api/document.dart' as j show Relationship;

mixin JSONAPIAdapter<T extends DataSupportMixin<T>> on RemoteAdapter<T> {
  @override
  Map<String, String> get headers => super.headers
    ..addAll({
      'Content-Type': 'application/vnd.api+json',
      'Accept': 'application/vnd.api+json',
    });

  // Transforms native format into JSON:API
  @override
  Map<String, dynamic> serialize(model) {
    final map = super.serialize(model);

    final relationships = <String, j.Relationship>{};

    // for (var relEntry in relationshipMetadata['HasMany'].entries) {
    //   final name = relEntry.key.toString();
    //   if (map[name] != null) {
    //     final keys = List<String>.from(map[name] as Iterable);
    //     final type = relEntry.value;
    //     final identifiers =
    //         DataId.byKeys(keys, manager, type: type.toString()).map((dataId) {
    //       return IdentifierObject(dataId.type, dataId.id.toString());
    //     });
    //     relationships[name] = ToMany(identifiers);
    //     map.remove(name);
    //   }
    // }

    // for (var relEntry in relationshipMetadata['BelongsTo'].entries) {
    //   final name = relEntry.key.toString();
    //   if (map[name] != null) {
    //     final key = map[name].toString();
    //     final type = relEntry.value;
    //     final dataId = DataId.byKey(key, manager, type: type.toString());
    //     relationships[name] =
    //         ToOne(IdentifierObject(dataId.type, dataId.id.toString()));
    //     map.remove(name);
    //   }
    // }

    final resource = ResourceObject(DataId.getType<T>(), map.id,
        attributes: map, relationships: relationships);
    map.remove('id');

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
  T deserialize(object, {String key, bool initialize = true}) {
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
          final dataId = manager.dataId(rel.linkage.id, type: rel.linkage.type);
          nativeMap[relEntry.key] = dataId.key;
        } else if (rel is ToMany) {
          nativeMap[relEntry.key] = rel.linkage
              .map((i) => manager.dataId(i.id, type: i.type).key)
              .toList();
        }
      }
    }

    nativeMap.addAll(obj.attributes);

    return super.deserialize(nativeMap, key: key, initialize: initialize);
  }

  void _saveIncluded(List<ResourceObject> included) {
    included ??= const [];
    for (var i in included) {
      final dataId = manager.dataId(i.id, type: i.type);
      final repo = relationshipRepositories[dataId.type] as RemoteAdapter;
      repo.deserialize(i, key: dataId.key);
    }
  }
}
