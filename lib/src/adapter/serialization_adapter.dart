part of flutter_data;

mixin _SerializationAdapter<T extends DataModelMixin<T>> on _BaseAdapter<T> {
  /// Returns a serialized version of a model of [T],
  /// as a [Map<String, dynamic>] ready to be JSON-encoded.
  @protected
  @visibleForTesting
  Future<Map<String, dynamic>> serializeAsync(T model,
      {bool withRelationships = true}) async {
    final map = serialize(model, withRelationships: withRelationships);

    // essentially converts keys to IDs
    for (final key in relationshipMetas.keys) {
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

  /// Returns a [DeserializedData] object when deserializing a given [data].
  ///
  @protected
  @visibleForTesting
  Future<DeserializedData<T>> deserializeAsync(Object? data,
      {String? key}) async {
    final result = DeserializedData<T>([], included: []);

    Future<Object?> _processIdAndAddInclude(id, Adapter? adapter) async {
      if (id is Map && adapter != null) {
        final data = await adapter.deserializeAsync(id as Map<String, dynamic>);
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

        // - process includes
        // - transform ids into keys to pass to the local deserializer
        for (final mapKey in mapIn.keys) {
          final metadata = relationshipMetas[mapKey];

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

        // Force key only if this is a single-model deserialization
        final model = deserialize(mapOut,
            key: key != null && data.length == 1 ? key : null);
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

  void _log(Adapter adapter, DataRequestLabel label) {
    adapter.log(label, '${models.toShortLog()} fetched from remote');
    final groupedIncluded = included.groupListsBy((m) => m._adapter.type);
    for (final e in groupedIncluded.entries) {
      if (e.value.isNotEmpty) {
        adapter.log(label, '  - with ${e.key} ${e.value.toShortLog()} ');
      }
    }
  }
}
