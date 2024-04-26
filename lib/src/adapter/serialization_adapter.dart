part of flutter_data;

mixin _SerializationAdapter<T extends DataModelMixin<T>> on _BaseAdapter<T> {
  /// Returns a serialized version of a model of [T],
  /// as a [Map<String, dynamic>] ready to be JSON-encoded.
  Future<Map<String, dynamic>> serialize(T model,
      {bool withRelationships = true}) async {
    final map = serializeLocal(model, withRelationships: withRelationships);

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

  (List<DataModelMixin>, List<DataModelMixin>) _deserialize(
      Adapter adapter, Object? data,
      {String? key}) {
    final result = (<DataModelMixin>[], <DataModelMixin>[]);

    Object? _processIdAndAddInclude(id, String relType) {
      final relAdapter = adapter.adapters[relType];
      if (id is Map && relAdapter != null) {
        final data =
            relAdapter._deserialize(relAdapter, id as Map<String, dynamic>);
        result.$2.addAll([...data.$1, ...data.$2]);
        id = data.$1.first.id;
      }
      if (id != null && relAdapter != null) {
        return relAdapter.core.getKeyForId(relAdapter.internalType, id);
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
          final metadata = adapter.relationshipMetas[mapKey];

          if (metadata != null) {
            final relType = metadata.type;

            if (metadata.serialize == false) {
              continue;
            }

            if (metadata.kind == 'BelongsTo') {
              // NOTE: when _processIdAndAddInclude was async, a sqlite bug
              // appeared when awaiting it (db turns to inMemory and closed)
              // so leaving everything sync works for now
              final key = _processIdAndAddInclude(mapIn[mapKey], relType);
              if (key != null) mapOut[mapKey] = key;
            }

            if (metadata.kind == 'HasMany') {
              mapOut[mapKey] = [
                for (final id in (mapIn[mapKey] as Iterable))
                  _processIdAndAddInclude(id, relType)
              ].nonNulls;
            }
          } else {
            // regular field mapping
            mapOut[mapKey] = mapIn[mapKey];
          }
        }

        // Force key only if this is a single-model deserialization
        final model = adapter.deserializeLocal(mapOut,
            key: (key != null && data.length == 1) ? key : null);
        result.$1.add(model as DataModelMixin);
      }
    }
    return result;
  }

  /// Returns a [DeserializedData] object when deserializing a given [data].
  ///
  DeserializedData<T> deserialize(Object? data, {String? key}) {
    final record = _deserialize(this as Adapter, data, key: key);
    return DeserializedData<T>(record.$1.cast<T>(), included: record.$2);
  }

  Future<DeserializedData<T>> deserializeAsync(Object? data,
      {String? key,
      bool save = false,
      bool ignoreReturn = false,
      bool notify = true}) async {
    final record =
        await runInIsolate<(DeserializedData?, List<String>)>((adapter) async {
      final deserialized = adapter.deserialize(data, key: key);
      if (deserialized.models.isEmpty || save == false)
        return (deserialized, <String>[]);
      final savedKeys = await adapter.saveManyLocal(
          [...deserialized.models.cast(), ...deserialized.included],
          async: false);
      return ignoreReturn ? (null, savedKeys!) : (deserialized, savedKeys!);
    });
    final (deserialized, savedKeys) = record;
    if (notify && savedKeys.isNotEmpty) {
      core._notify(savedKeys, type: DataGraphEventType.updateNode);
    }
    return (deserialized as DeserializedData<T>?) ?? DeserializedData<T>([]);
  }
}

/// A utility class used to return deserialized main [models] AND [included] models.
class DeserializedData<T extends DataModelMixin<T>> {
  const DeserializedData(this.models, {this.included = const []});
  final List<T> models;
  final List<DataModelMixin> included;
  T? get model => models.singleOrNull;
}
