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

  // Transforms native format into JSON:API
  @override
  Map<String, dynamic> serialize(model) {
    final map = localSerialize(model);

    final relationships = <String, j.Relationship>{};

    for (final relEntry in relationshipsFor().entries) {
      final field = relEntry.key;
      final relType = relEntry.value['type'] as String;

      if (map[field] != null) {
        if (relEntry.value['kind'] == 'HasMany') {
          final keys = List<String>.from(map[field] as Iterable);
          final identifiers = keys.map((key) {
            return IdentifierObject(relType, manager.getId(key));
          });
          relationships[field] = ToMany(identifiers);
        } else if (relEntry.value['kind'] == 'BelongsTo') {
          final key = map[field].toString();
          relationships[field] =
              ToOne(IdentifierObject(relType, manager.getId(key)));
        }
      }

      map.remove(field);
    }

    final id = map.remove('id');
    final resource = ResourceObject(type, id?.toString(),
        attributes: map, relationships: relationships);

    return Document(ResourceData(resource)).toJson();
  }

  // Transforms JSON:API into native format
  @override
  DeserializedData<T, DataSupport<dynamic>> deserialize(dynamic data,
      {String key, bool save = true}) {
    final result = DeserializedData<T, DataSupport<dynamic>>([], included: []);
    ResourceCollectionData collectionData;

    if (data is! ResourceCollectionData) {
      // single resource object (used when deserializing includes)
      if (data is ResourceObject) {
        collectionData = ResourceCollectionData([data]);
      }
      // multiple document json
      if (data is Map && data['data'] is List) {
        collectionData = ResourceCollectionData.fromJson(data);
      }
      // single document json
      if (data is Map && data['data'] is Map) {
        final resourceData = ResourceData.fromJson(data);
        collectionData = ResourceCollectionData([resourceData.resourceObject],
            included: resourceData.included);
      }
    } else {
      collectionData = data as ResourceCollectionData;
    }

    if (collectionData.included != null) {
      for (final include in collectionData.included) {
        final key = manager.getKeyForId(include.type, include.id);
        final type = Repository.getType(include.type);
        final repo = relatedRepositories[type] as RemoteAdapter;
        final model = repo?.deserialize(include, key: key, save: save)?.model;
        result.included.add(model);
      }
    }

    for (final obj in collectionData.collection) {
      final mapOut = <String, dynamic>{};

      mapOut['id'] = obj.id;

      if (obj.relationships != null) {
        for (final relEntry in obj.relationships.entries) {
          final rel = relEntry.value;
          if (rel is ToOne && rel.linkage != null) {
            final key = manager.getKeyForId(rel.linkage.type, rel.linkage.id,
                keyIfAbsent: Repository.generateKey(rel.linkage.type));
            mapOut[relEntry.key] = key;
          } else if (rel is ToMany) {
            mapOut[relEntry.key] = rel.linkage
                .map((i) => manager.getKeyForId(i.type, i.id,
                    keyIfAbsent: Repository.generateKey(i.type)))
                .toList();
          }
        }
        mapOut.addAll(obj.attributes);
      }

      final model = localDeserialize(mapOut);
      result.models.add(model.init(manager: manager, key: key, save: save));
    }

    return result;
  }
}
