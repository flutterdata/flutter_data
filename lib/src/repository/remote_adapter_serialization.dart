part of flutter_data;

mixin _RemoteAdapterSerialization<T extends DataModel<T>> on _RemoteAdapter<T> {
  @override
  Map<String, dynamic> serialize(T model) {
    return localAdapter.serialize(model);
  }

  @override
  DeserializedData<T> deserialize(Object? data) {
    final result = DeserializedData<T>([], included: []);

    Object? _processIdAndAddInclude(id, RemoteAdapter? adapter) {
      if (id is Map && adapter != null) {
        final data = adapter.deserialize(id as Map<String, dynamic>);
        result.included
          ..add(data.model as DataModel<DataModel>)
          ..addAll(data.included);
        id = data.model!.id;
      }
      if (id != null && adapter != null) {
        return graph.getKeyForId(adapter.internalType, id,
            keyIfAbsent: DataHelpers.generateKey(adapter.internalType));
      }
      return null;
    }

    if (data == null || data == '') {
      return result;
    }

    // since data is not null, touch local storage
    localAdapter._touchLocalStorage();

    if (data is Map<String, dynamic>) {
      data = [data];
    }

    if (data is Iterable) {
      for (final _ in data) {
        final mapIn = Map<String, dynamic>.from(_ as Map);
        final mapOut = <String, dynamic>{};

        final relationships = localAdapter.relationshipsFor();

        // - process includes
        // - transform ids into keys to pass to the local deserializer
        for (final mapKey in mapIn.keys) {
          final metadata = relationships[mapKey];

          if (metadata != null) {
            final relType = metadata['type'] as String;

            if (metadata['serialize'] == 'false') {
              continue;
            }

            if (metadata['kind'] == 'BelongsTo') {
              final key =
                  _processIdAndAddInclude(mapIn[mapKey], adapters[relType]!);
              if (key != null) mapOut[mapKey] = key;
            }

            if (metadata['kind'] == 'HasMany') {
              mapOut[mapKey] = [
                for (final id in (mapIn[mapKey] as Iterable))
                  _processIdAndAddInclude(id, adapters[relType]!)
              ].filterNulls;
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
class DeserializedData<T extends DataModel<T>> {
  const DeserializedData(this.models, {this.included = const []});
  final List<T> models;
  final List<DataModel> included;
  T? get model => models.singleOrNull;

  void _log(RemoteAdapter adapter, DataRequestLabel label) {
    adapter.log(label, '${models.toShortLog()} fetched from remote');
    final groupedIncluded = included.groupListsBy((m) => m.remoteAdapter.type);
    for (final e in groupedIncluded.entries) {
      if (e.value.isNotEmpty) {
        adapter.log(label, '  - with ${e.key} ${e.value.toShortLog()} ');
      }
    }
  }
}
