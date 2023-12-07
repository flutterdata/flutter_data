part of flutter_data;

mixin _RemoteAdapterWatch<T extends DataModelMixin<T>> on _RemoteAdapter<T> {
  @protected
  DataStateNotifier<List<T>> watchAllNotifier({
    bool? remote,
    Map<String, dynamic>? params,
    Map<String, String>? headers,
    bool? syncLocal,
    String? finder,
    DataRequestLabel? label,
  }) {
    remote ??= _remote;
    syncLocal ??= false;

    final maybeFinder = _internalHolder?.finders[finder]?.call(this);
    final finderFn = maybeFinder is DataFinderAll<T> ? maybeFinder : findAll;

    // we can't use `findAll`'s default internal label
    // because we need a label to handle events
    label ??= DataRequestLabel('watchAll', type: internalType);

    log(label, 'initializing');

    // closure to get latest models
    List<T> _getUpdatedModels() {
      return localAdapter.findAll();
    }

    final notifier = DataStateNotifier<List<T>>(
      data: DataState(_getUpdatedModels(), isLoading: remote!),
    );

    notifier._reloadFn = () async {
      if (!notifier.mounted) {
        return;
      }

      if (remote!) {
        notifier.updateWith(isLoading: true);
      }

      await finderFn(
        remote: remote,
        params: params,
        headers: headers,
        syncLocal: syncLocal,
        label: label,
        onError: (e, label, _) async {
          try {
            await onError<List<T>>(e, label);
          } on DataException catch (err) {
            e = err;
          } catch (_) {
            rethrow;
          }
          if (notifier.mounted) {
            notifier.updateWith(isLoading: false, exception: e);
          }
          return [];
        },
      );
      if (remote) {
        // trigger doneLoading to ensure state is updated with isLoading=false
        core._notify([label.toString()], type: DataGraphEventType.doneLoading);
      }
    };

    // kick off
    notifier.reload();

    final throttleDuration = ref.read(coreNotifierThrottleDurationProvider);
    final throttledNotifier = core.throttle(() => throttleDuration);

    final states = <DataState<List<T>>>[];

    final dispose = throttledNotifier.addListener((events) {
      if (!notifier.mounted) {
        return;
      }

      for (final event in events) {
        // handle done loading
        if (notifier.data.isLoading &&
            event.keys.last == label.toString() &&
            event.type == DataGraphEventType.doneLoading) {
          final models = _getUpdatedModels();
          states.add(DataState(models, isLoading: false, exception: null));
        }

        if (notifier.data.isLoading == false &&
            event.type.isNode &&
            event.keys.first.startsWith(internalType)) {
          final models = _getUpdatedModels();
          log(label!, 'updated models', logLevel: 2);
          states.add(DataState(
            models,
            isLoading: notifier.data.isLoading,
            exception: notifier.data.exception,
            stackTrace: notifier.data.stackTrace,
          ));
        }

        if (event.type == DataGraphEventType.clear &&
            event.keys.first.startsWith(internalType)) {
          log(label!, 'clear local storage', logLevel: 2);
          states.add(DataState([], isLoading: false, exception: null));
        }
      }

      _updateFromStates(states, notifier);
    });

    notifier.onDispose = () {
      log(label!, 'disposing');
      dispose();
    };
    return notifier;
  }

  @protected
  DataStateNotifier<T?> watchOneNotifier(
    String key, {
    bool? remote,
    Map<String, dynamic>? params,
    Map<String, String>? headers,
    AlsoWatch<T>? alsoWatch,
    String? finder,
    DataRequestLabel? label,
  }) {
    final id = core.getIdForKey(key);

    remote ??= _remote;
    final maybeFinder = _internalHolder?.finders[finder]?.call(this);
    final finderFn = maybeFinder is DataFinderOne<T> ? maybeFinder : findOne;

    // we can't use `findOne`'s default internal label
    // because we need a label to handle events
    label ??= DataRequestLabel('watchOne',
        id: key.detypify().toString(), type: internalType);

    var alsoWatchPairs = <List<String>>{};

    // closure to get latest model and watchable relationship pairs
    T? _getUpdatedModel() {
      return core._store.runInTransaction(TxMode.read, () {
        final model = localAdapter.findOne(key);
        if (model != null) {
          // get all metas provided via `alsoWatch`
          final metas = alsoWatch
              ?.call(RelationshipGraphNode<T>())
              .whereType<RelationshipMeta>();

          // recursively get applicable watch key pairs for each meta -
          // from top to bottom (e.g. `p`, `p.familia`, `p.familia.cottage`)
          alsoWatchPairs = {
            ...?metas
                ?.map((meta) => _getPairsForMeta(meta._top, model._key!))
                .nonNulls
                .expand((_) => _)
          };
        } else {
          // if there is no model nothing should be watched, reset pairs
          alsoWatchPairs = {};
        }
        return model;
      });
    }

    final notifier = DataStateNotifier<T?>(
      data: DataState(_getUpdatedModel(), isLoading: remote!),
    );

    final alsoWatchNames = alsoWatch
            ?.call(RelationshipGraphNode<T>())
            .whereType<RelationshipMeta>()
            .map((m) => m.name) ??
        {};
    log(label,
        'initializing${alsoWatchNames.isNotEmpty ? ' (and also watching: ${alsoWatchNames.join(', ')})' : ''}');

    notifier._reloadFn = () async {
      if (!notifier.mounted || id == null) return;

      if (remote!) {
        notifier.updateWith(isLoading: true);
      }

      final model = await finderFn(
        id,
        remote: remote,
        params: params,
        headers: headers,
        label: label,
        onError: (e, label, _) async {
          try {
            await onError<T>(e, label);
          } on DataException catch (err) {
            e = err;
          } catch (_) {
            rethrow;
          }
          if (notifier.mounted) {
            notifier.updateWith(isLoading: false, exception: e);
          }
          return null;
        },
      );
      // trigger doneLoading to ensure state is updated with isLoading=false
      final modelKey = model?._key;
      if (remote && modelKey != null) {
        core._notify([modelKey, label.toString()],
            type: DataGraphEventType.doneLoading);
      }
    };

    // trigger local + async loading
    notifier.reload();

    // local buffer useful to reduce amount of notifier updates
    var bufferModel = notifier.data.model;

    final throttleDuration = ref.read(coreNotifierThrottleDurationProvider);
    final throttledNotifier = core.throttle(() => throttleDuration);

    final states = <DataState<T?>>[];

    // start listening to graph for further changes
    final dispose = throttledNotifier.addListener((events) {
      if (!notifier.mounted) return;

      // get the latest updated model with watchable relationships
      // (_alsoWatchPairs) in order to determine whether there is
      // something that will cause an event (with the introduction
      // of `andEach` even seemingly unrelated models could trigger)
      bufferModel = _getUpdatedModel();

      key = bufferModel?._key ?? key;

      for (final event in events) {
        if (event.keys.contains(key)) {
          // handle done loading
          if (notifier.data.isLoading &&
              event.keys.last == label.toString() &&
              event.type == DataGraphEventType.doneLoading) {
            states
                .add(DataState(bufferModel, isLoading: false, exception: null));
          }

          // add/update
          if (event.type == DataGraphEventType.updateNode) {
            if (notifier.data.isLoading == false) {
              log(label!, 'added/updated node ${event.keys}', logLevel: 2);
              states.add(DataState(
                bufferModel,
                isLoading: notifier.data.isLoading,
                exception: notifier.data.exception,
                stackTrace: notifier.data.stackTrace,
              ));
            }
          }

          // temporarily restore removed pair so that watchedRelationshipUpdate
          // has a chance to apply the update
          if (event.type == DataGraphEventType.removeEdge &&
              !event.keys.first.startsWith('id:')) {
            alsoWatchPairs.add(event.keys);
          }
        }

        // handle deletion
        if ([DataGraphEventType.removeNode, DataGraphEventType.clear]
                .contains(event.type) &&
            bufferModel == null) {
          log(label!, 'removed node ${event.keys}', logLevel: 2);
          states.add(DataState(
            null,
            isLoading: notifier.data.isLoading,
            exception: notifier.data.exception,
            stackTrace: notifier.data.stackTrace,
          ));
        }

        // updates on watched relationships condition
        final watchedRelationshipUpdate = event.type.isEdge &&
            alsoWatchPairs
                .where((pair) =>
                    pair.sorted().toString() == event.keys.sorted().toString())
                .isNotEmpty;

        // updates on watched models (of relationships) condition
        final watchedModelUpdate = event.type.isNode &&
            alsoWatchPairs
                .where((pair) => pair.contains(event.keys.first))
                .isNotEmpty;

        // if model is loaded and any condition passes, notify update
        if (notifier.data.isLoading == false &&
            (watchedRelationshipUpdate || watchedModelUpdate)) {
          log(label!, 'relationship update ${event.keys}', logLevel: 2);
          states.add(DataState(
            bufferModel,
            isLoading: notifier.data.isLoading,
            exception: notifier.data.exception,
            stackTrace: notifier.data.stackTrace,
          ));
        }
      }

      _updateFromStates(states, notifier);
    });

    notifier.onDispose = () {
      log(label!, 'disposing');
      dispose();
    };
    return notifier;
  }

  // `S` could be `T` or `List<T>`
  void _updateFromStates<S>(
      List<DataState<S>> states, DataStateNotifier<S> notifier) {
    // calculate final state & drain
    final mergedState = states.fold<DataState<S>?>(null, (acc, state) {
      return acc == null ? state : acc.merge(state);
    });
    states.clear();

    if (mergedState != null) {
      notifier.updateWith(
        model: mergedState.model,
        isLoading: mergedState.isLoading,
        exception: mergedState.exception,
        stackTrace: mergedState.stackTrace,
      );
    }
  }

  Iterable<List<String>> _getPairsForMeta(
      RelationshipMeta? meta, String ownerKey) {
    if (meta == null) return {};
    final edges = core._edgeBox
        .query((Edge_.from.equals(ownerKey) & Edge_.name.equals(meta.name)) |
            (Edge_.to.equals(ownerKey) & Edge_.inverseName.equals(meta.name)))
        .build()
        .find();
    final relationshipKeys = {
      for (final e in edges) e.from == ownerKey ? e.to : e.from
    };

    return {
      // include key pairs of (owner, key)
      for (final key in relationshipKeys) [ownerKey, key],
      // recursively include key pairs for other requested relationships
      for (final childKey in relationshipKeys)
        _getPairsForMeta(meta.child, childKey).expand((_) => _).toList()
    };
  }
}

final coreNotifierThrottleDurationProvider =
    Provider<Duration>((ref) => Duration.zero);
