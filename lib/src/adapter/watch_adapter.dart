part of flutter_data;

mixin _WatchAdapter<T extends DataModelMixin<T>> on _RemoteAdapter<T> {
  /// Watches a provider wrapping [watchAllNotifier]
  /// which allows the watcher to be notified of changes
  /// on any model of this [type].
  ///
  /// Example: Watch all models of type `books` on a Riverpod hook-enabled app.
  ///
  /// ```
  /// ref.books.watchAll();
  /// ```
  DataState<List<T>> watchAll({
    bool remote = false,
    Map<String, dynamic>? params,
    Map<String, String>? headers,
    bool syncLocal = false,
    String? finder,
    DataRequestLabel? label,
  }) {
    final provider = watchAllProvider(
      remote: remote,
      params: params,
      headers: headers,
      syncLocal: syncLocal,
      finder: finder,
      label: label,
    );
    return internalWatch!(provider);
  }

  /// Watches a provider wrapping [watchOneNotifier]
  /// which allows the watcher to be notified of changes
  /// on a specific model of this [type], optionally reacting
  /// to selected relationships of this model via [alsoWatch].
  ///
  /// Example: Watch model of type `books` and `id=1` along
  /// with its `author` relationship on a Riverpod hook-enabled app.
  ///
  /// ```
  /// ref.books.watchOne(1, alsoWatch: (book) => [book.author]);
  /// ```
  DataState<T?> watchOne(
    Object model, {
    bool remote = false,
    Map<String, dynamic>? params,
    Map<String, String>? headers,
    AlsoWatch<T>? alsoWatch,
    String? finder,
    DataRequestLabel? label,
  }) {
    final provider = watchOneProvider(
      model,
      remote: remote,
      params: params,
      headers: headers,
      alsoWatch: alsoWatch,
      finder: finder,
      label: label,
    );
    return internalWatch!(provider);
  }

  // notifiers

  DataStateNotifier<List<T>> watchAllNotifier(
      {bool remote = false,
      Map<String, dynamic>? params,
      Map<String, String>? headers,
      bool syncLocal = false,
      String? finder,
      DataRequestLabel? label}) {
    final provider = watchAllProvider(
      remote: remote,
      params: params,
      headers: headers,
      syncLocal: syncLocal,
      finder: finder,
      label: label,
    );
    return internalWatch!(provider.notifier);
  }

  // TODO should be watchOneNotifierById (the other one should accept a key)
  DataStateNotifier<T?> watchOneNotifier(Object model,
      {bool remote = false,
      Map<String, dynamic>? params,
      Map<String, String>? headers,
      AlsoWatch<T>? alsoWatch,
      String? finder,
      DataRequestLabel? label}) {
    return internalWatch!(watchOneProvider(
      model,
      remote: remote,
      params: params,
      headers: headers,
      alsoWatch: alsoWatch,
      finder: finder,
      label: label,
    ).notifier);
  }

  // private notifiers

  @protected
  DataStateNotifier<List<T>> _watchAllNotifier({
    bool remote = false,
    Map<String, dynamic>? params,
    Map<String, String>? headers,
    bool syncLocal = false,
    String? finder,
    DataRequestLabel? label,
  }) {
    // we can't use `findAll`'s default internal label
    // because we need a label to handle events
    label ??= DataRequestLabel('watchAll', type: internalType);
    log(label, 'initializing');

    final notifier = DataStateNotifier<List<T>>(
      data: DataState(findAllLocal(), isLoading: remote),
    );

    notifier._reloadFn = (notifier) async {
      if (!notifier.mounted || remote == false) {
        return;
      }

      notifier.updateWith(isLoading: true);

      final _finderFn = _internalHolder?.finders[finder]?.call(this);
      final finderFn = _finderFn is DataFinderAll<T> ? _finderFn : findAll;

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

      // trigger doneLoading to ensure state is updated with isLoading=false
      core._notify([label.toString()], type: DataGraphEventType.doneLoading);
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
          states.add(
              DataState(findAllLocal(), isLoading: false, exception: null));
        }

        if (notifier.data.isLoading == false &&
            event.type.isNode &&
            event.keys.first.startsWith(internalType)) {
          log(label!, 'updated models', logLevel: 2);
          states.add(DataState(
            findAllLocal(),
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
  DataStateNotifier<T?> _watchOneNotifier(
    String key, {
    bool remote = false,
    Map<String, dynamic>? params,
    Map<String, String>? headers,
    AlsoWatch<T>? alsoWatch,
    String? finder,
    DataRequestLabel? label,
  }) {
    // TODO improve key/id passing logic
    final id = core.getIdForKey(key);

    // we can't use `findOne`'s default internal label
    // because we need a label to handle events
    label ??= DataRequestLabel('watchOne',
        id: key.detypify()?.toString(), type: internalType);

    var alsoWatchPairs = <(String, String)>{};

    // closure to get latest model and watchable relationship pairs
    T? _getUpdatedModel() {
      final model = findOneLocal(key);
      if (model != null) {
        // get all metas provided via `alsoWatch`
        final metas = alsoWatch
            ?.call(RelationshipGraphNode<T>())
            .whereType<RelationshipMeta>();

        // recursively get applicable watch key pairs for each meta -
        // from top to bottom (e.g. `p`, `p.familia`, `p.familia.cottage`)
        if (metas != null) {
          alsoWatchPairs = metas
              .map((meta) => _getPairsForMeta(meta._top, model._key!))
              .expand((e) => e)
              .toSet();
        }
      } else {
        // if there is no model nothing should be watched, reset pairs
        alsoWatchPairs = {};
      }
      return model;
    }

    final notifier = DataStateNotifier<T?>(
      data: DataState(_getUpdatedModel(), isLoading: remote),
    );

    final alsoWatchNames = alsoWatch
            ?.call(RelationshipGraphNode<T>())
            .whereType<RelationshipMeta>()
            .map((m) => m.name) ??
        {};

    log(label,
        'initializing${alsoWatchNames.isNotEmpty ? ' (and also watching: ${alsoWatchNames.join(', ')})' : ''}');

    notifier._reloadFn = (notifier) async {
      if (!notifier.mounted || id == null || remote == false) return;

      notifier.updateWith(isLoading: true);

      final _finderFn = _internalHolder?.finders[finder]?.call(this);
      final finderFn = _finderFn is DataFinderOne<T> ? _finderFn : findOne;

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
      if (model?._key != null) {
        core._notify([model!._key!, label.toString()],
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
            alsoWatchPairs.add((event.keys.first, event.keys.last));
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
                    pair.unorderedEquals((event.keys.first, event.keys.last)))
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

  Set<(String, String)> _getPairsForMeta(
      RelationshipMeta? meta, String ownerKey) {
    if (meta == null) return {};

    final relationshipKeys = _keysFor(ownerKey, meta.name);

    return {
      // include key pairs of (owner, key)
      for (final key in relationshipKeys) (ownerKey, key),
      // recursively include key pairs for other requested relationships
      for (final childKey in relationshipKeys)
        ..._getPairsForMeta(meta.child, childKey)
    };
  }

  // providers

  AutoDisposeStateNotifierProvider<DataStateNotifier<List<T>>,
      DataState<List<T>>> watchAllProvider({
    bool remote = false,
    Map<String, dynamic>? params,
    Map<String, String>? headers,
    bool syncLocal = false,
    String? finder,
    DataRequestLabel? label,
  }) {
    return _watchAllProvider(
      WatchArgs(
        remote: remote,
        params: params,
        headers: headers,
        syncLocal: syncLocal,
        finder: finder,
        label: label,
      ),
    );
  }

  late final _watchAllProvider = StateNotifierProvider.autoDispose
      .family<DataStateNotifier<List<T>>, DataState<List<T>>, WatchArgs<T>>(
          (ref, args) {
    return _watchAllNotifier(
      remote: args.remote,
      params: args.params,
      headers: args.headers,
      syncLocal: args.syncLocal,
      finder: args.finder,
      label: args.label,
    );
  });

  AutoDisposeStateNotifierProvider<DataStateNotifier<T?>, DataState<T?>>
      watchOneProvider(
    Object model, {
    bool remote = false,
    Map<String, dynamic>? params,
    Map<String, String>? headers,
    AlsoWatch<T>? alsoWatch,
    String? finder,
    DataRequestLabel? label,
  }) {
    final key = core.getKeyForModelOrId(internalType, model);

    final relationshipMetas = alsoWatch
        ?.call(RelationshipGraphNode<T>())
        .whereType<RelationshipMeta>()
        .toImmutableList();

    return _watchOneProvider(
      WatchArgs(
        key: key,
        remote: remote,
        params: params,
        headers: headers,
        relationshipMetas: relationshipMetas,
        alsoWatch: alsoWatch,
        finder: finder,
        label: label,
      ),
    );
  }

  late final _watchOneProvider = StateNotifierProvider.autoDispose
      .family<DataStateNotifier<T?>, DataState<T?>, WatchArgs<T>>((ref, args) {
    return _watchOneNotifier(
      args.key!,
      remote: args.remote,
      params: args.params,
      headers: args.headers,
      alsoWatch: args.alsoWatch,
      finder: args.finder,
      label: args.label,
    );
  });

  /// Watch this model (local)
  T watch(T model) {
    return watchOne(model, remote: false).model!;
  }

  /// Notifier for watched model (local)
  DataStateNotifier<T?> notifierFor(T model) {
    return watchOneNotifier(model, remote: false);
  }

  void triggerNotify() {
    core._notify([internalType], type: DataGraphEventType.updateNode);
  }
}

final coreNotifierThrottleDurationProvider =
    Provider<Duration>((ref) => Duration.zero);
