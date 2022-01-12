part of flutter_data;

mixin _RemoteAdapterSerialization<T extends DataModel<T>> on _RemoteAdapter<T> {
  @override
  Map<String, dynamic> serialize(T model) {
    final map = localAdapter.serialize(model).filterNulls;

    final relationships = <String, dynamic>{};

    for (final field in localAdapter.relationshipsFor(model).keys) {
      final key = keyForField(field);

      if (map[field] != null) {
        if (map[field] is HasMany) {
          relationships[key] = (map[field] as HasMany).map((e) => e.id).toList();
        }
        if (map[field] is BelongsTo) {
          relationships[key] = (map[field] as BelongsTo).value?.id;
        }
      }
      map.remove(field);
    }

    return map..addAll(relationships.filterNulls);
  }

  @override
  DeserializedData<T, DataModel> deserialize(dynamic data, {String? key}) {
    final result = DeserializedData<T, DataModel>([], included: []);

    Object addIncluded(Object id, RemoteAdapter? adapter) {
      if (id is Map && adapter != null) {
        final data = adapter.deserialize(id as Map<String, dynamic>);
        result.included
          ..add(data.model! as DataModel<DataModel>)
          ..addAll(data.included);
        return data.model!.id!;
      }
      return id;
    }

    if (data == null || data == '') {
      return result;
    }
    if (data is Map) {
      // ignore: parameter_assignments
      data = [data];
    }

    if (data is Iterable) {
      for (final mapIn in data.filterNulls.map((e) => e as Map<String, dynamic>)) {
        final mapOut = <String, dynamic>{};

        final relationships = localAdapter.relationshipsFor();

        for (final mapInKey in mapIn.keys.where((key) => mapIn[key] != null)) {
          final mapOutKey = fieldForKey(mapInKey);
          final metadata = relationships[mapOutKey];

          if (metadata != null) {
            final _type = metadata['type']! as String;

            if (metadata['kind'] == 'BelongsTo') {
              final id = addIncluded(mapIn[mapInKey] as Object, adapters[_type]);
              mapOut[mapOutKey] = graph.getKeyForId(_type, id, keyIfAbsent: DataHelpers.generateKeyFromString(_type));
            }

            if (metadata['kind'] == 'HasMany') {
              mapOut[mapOutKey] = (mapIn[mapInKey] as Iterable)
                  .filterNulls
                  .map((id) {
                    id = addIncluded(id, adapters[_type]);
                    return graph.getKeyForId(_type, id, keyIfAbsent: DataHelpers.generateKeyFromString(_type));
                  })
                  .filterNulls
                  .toImmutableList();
            }
          } else {
            // regular field mapping
            mapOut[mapOutKey] = mapIn[mapInKey];
          }
        }

        final model = localAdapter.deserialize(mapOut);
        if (model.id != null) {
          model._initialize(adapters, key: key, save: true);
          result.models.add(model);
        }
      }
    }

    return result;
  }

  /// A suffix appended to all [BelongsTo] relationships in serialized form.
  ///
  /// Example:
  ///
  /// ```
  /// {
  ///  "user_id": 1,
  ///  "id": 1,
  ///  "title": "delectus aut autem",
  ///  "completed": false
  ///}
  ///```
  @protected
  String get identifierSuffix => '_id';

  Map<String, Map<String, Object?>> get _belongsTos => Map.fromEntries(
        localAdapter.relationshipsFor().entries.where((e) => e.value['kind'] == 'BelongsTo'),
      );

  /// Transforms a [key] into a model's field.
  ///
  /// This mapping can also be done via `json_serializable`'s `@JsonKey`.
  /// If both are used, `fieldForKey` will be applied before
  /// reaching `fromJson`.
  @protected
  @visibleForTesting
  String fieldForKey(String key) {
    if (key.endsWith(identifierSuffix)) {
      final keyWithoutId = key.substring(0, key.length - identifierSuffix.length);
      if (_belongsTos.keys.contains(keyWithoutId)) {
        return keyWithoutId;
      }
    }
    return key;
  }

  /// Transforms a model's [field] into a key.
  ///
  /// This mapping can also be done via `json_serializable`'s `@JsonKey`.
  @protected
  @visibleForTesting
  String keyForField(String field) {
    if (_belongsTos.keys.contains(field)) {
      return '$field$identifierSuffix';
    }
    return field;
  }
}
