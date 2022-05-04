part of flutter_data;

mixin _RemoteAdapterSerialization<T extends DataModel<T>> on _RemoteAdapter<T> {
  @override
  Map<String, dynamic> serialize(T model) {
    return localAdapter.serialize(model);
  }

  @override
  DeserializedData<T> deserialize(Object? data) {
    final result = DeserializedData<T>([], included: []);

    Object? addIncluded(id, RemoteAdapter? adapter) {
      if (id is Map && adapter != null) {
        final data = adapter.deserialize(id as Map<String, dynamic>);
        result.included
          ..add(data.model as DataModel<DataModel>)
          ..addAll(data.included);
        return data.model!.id;
      }
      return id;
    }

    if (data == null || data == '') {
      return result;
    }

    // since data is not null, touch local storage
    localAdapter._touchLocalStorage();

    if (data is Map) {
      data = [data];
    }

    if (data is Iterable) {
      for (final mapIn in data) {
        final mapOut = <String, dynamic>{};

        final relationships = localAdapter.relationshipsFor();

        for (final mapInKey in mapIn.keys) {
          final mapOutKey = mapInKey.toString();
          final metadata = relationships[mapOutKey];

          if (metadata != null) {
            final _type = metadata['type'] as String;

            if (metadata['kind'] == 'BelongsTo') {
              final id = addIncluded(mapIn[mapInKey], adapters[_type]);
              mapOut[mapOutKey] = id == null
                  ? null
                  : graph.getKeyForId(_type, id,
                      keyIfAbsent: DataHelpers.generateKey(_type));
            }

            if (metadata['kind'] == 'HasMany') {
              final _mapOut = [];
              for (var id in (mapIn[mapInKey] as Iterable)) {
                id = addIncluded(id, adapters[_type]);
                if (id != null) {
                  _mapOut.add(graph.getKeyForId(_type, id,
                      keyIfAbsent: DataHelpers.generateKey(_type)));
                }
              }
              mapOut[mapOutKey] = _mapOut;
            }
          } else {
            // regular field mapping
            mapOut[mapOutKey] = mapIn[mapInKey];
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
        adapter.log(
            label, '  - with ${e.key} ${e.value.map((m) => m.id).toSet()} ');
      }
    }
  }
}
