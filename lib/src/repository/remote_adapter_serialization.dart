part of flutter_data;

mixin _RemoteAdapterSerialization<T extends DataModelMixin<T>>
    on _RemoteAdapter<T> {
  @override
  Future<Map<String, dynamic>> serialize(T model,
      {bool withRelationships = true}) async {
    final map =
        localAdapter.serialize(model, withRelationships: withRelationships);

    // essentially converts keys to IDs
    for (final key in localAdapter.relationshipMetas.keys) {
      if (map[key] is Iterable) {
        map[key] = (map[key] as Iterable)
            .map((k) => core.getIdForKey(k.toString()))
            .nonNulls
            .toList();
      } else if (map[key] != null) {
        map[key] = core.getIdForKey(map[key].toString());
      }
      if (map[key] == null) map.remove(key);
    }
    return map;
  }

  @override
  Future<DeserializedData<T>> deserialize(Object? data) async {
    final result = DeserializedData<T>([], included: []);

    Future<Object?> _processIdAndAddInclude(id, RemoteAdapter? adapter) async {
      if (id is Map && adapter != null) {
        final data = await adapter.deserialize(id as Map<String, dynamic>);
        result.included
          ..add(data.model as DataModelMixin<DataModelMixin>)
          ..addAll(data.included);
        id = data.model!.id;
      }
      if (id != null && adapter != null) {
        return core.getKeyForId(adapter.internalType, id);
      }
      return null;
    }

    if (data == null || data == '') {
      return result;
    }

    if (data is Map<String, dynamic>) {
      data = [data];
    }

    if (data is Iterable) {
      for (final map in data) {
        final mapIn = Map<String, dynamic>.from(map as Map);
        final mapOut = <String, dynamic>{};

        final relationships = localAdapter.relationshipMetas;

        // - process includes
        // - transform ids into keys to pass to the local deserializer
        for (final mapKey in mapIn.keys) {
          final metadata = relationships[mapKey];

          if (metadata != null) {
            final relType = metadata.type;

            if (metadata.serialize == false) {
              continue;
            }

            if (metadata.kind == 'BelongsTo') {
              final key = await _processIdAndAddInclude(
                  mapIn[mapKey], adapters[relType]!);
              if (key != null) mapOut[mapKey] = key;
            }

            if (metadata.kind == 'HasMany') {
              mapOut[mapKey] = [
                for (final id in (mapIn[mapKey] as Iterable))
                  await _processIdAndAddInclude(id, adapters[relType]!)
              ].nonNulls;
            }
          } else {
            // regular field mapping
            mapOut[mapKey] = mapIn[mapKey];
          }
        }

        final model = localAdapter.deserialize(mapOut);
        result.models.add(model);
      }
    }

    return result;
  }
}

/// A utility class used to return deserialized main [models] AND [included] models.
class DeserializedData<T extends DataModelMixin<T>> {
  const DeserializedData(this.models, {this.included = const []});
  final List<T> models;
  final List<DataModelMixin> included;
  T? get model => models.singleOrNull;

  void _log(RemoteAdapter adapter, DataRequestLabel label) {
    adapter.log(label, '${models.toShortLog()} fetched from remote');
    final groupedIncluded = included.groupListsBy((m) => m._remoteAdapter.type);
    for (final e in groupedIncluded.entries) {
      if (e.value.isNotEmpty) {
        adapter.log(label, '  - with ${e.key} ${e.value.toShortLog()} ');
      }
    }
  }
}
