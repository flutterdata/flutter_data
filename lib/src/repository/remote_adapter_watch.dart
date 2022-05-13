part of flutter_data;

class RelationshipData<T extends DataModel<T>> {
  final Map<String, RelationshipDataItem<T>> items;
  RelationshipData(this.items);
}

class RelationshipDataItem<T extends DataModel<T>> {
  final String name;
  final String? inverseName;
  final String type;
  final String kind;
  final bool serialize;
  final Relationship? Function(T) instance;

  const RelationshipDataItem({
    required this.name,
    this.inverseName,
    required this.type,
    required this.kind,
    this.serialize = true,
    required this.instance,
  });
}

mixin _RemoteAdapterWatch<T extends DataModel<T>> on _RemoteAdapter<T> {
  @protected
  DataStateNotifier<List<T>?> watchAllNotifier({
    bool? remote,
    Map<String, dynamic>? params,
    Map<String, String>? headers,
    bool? syncLocal,
    String? finder,
    DataRequestLabel? label,
  }) {
    remote ??= _remote;
    syncLocal ??= false;

    final _maybeFinder = _internalHolder?.finders[finder]?.call(this);
    final _finder = _maybeFinder is DataFinderAll<T> ? _maybeFinder : findAll;

    // we can't use `findAll`'s default internal label
    // because we need a label to handle events
    label ??= DataRequestLabel('watchAll', type: internalType);

    log(label, 'initializing');

    // closure to get latest models
    List<T>? _getUpdatedModels() {
      return localAdapter.findAll();
    }

    final _notifier = DataStateNotifier<List<T>?>(
      data: DataState(_getUpdatedModels(), isLoading: remote!),
    );

    _notifier._reloadFn = () async {
      if (!_notifier.mounted) {
        return;
      }

      if (remote!) {
        _notifier.updateWith(isLoading: true);
      }

      await _finder(
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
          if (_notifier.mounted) {
            _notifier.updateWith(isLoading: false, exception: e);
          }
          return null;
        },
      );
      if (remote) {
        // trigger doneLoading to ensure state is updated with isLoading=false
        graph._notify([label.toString()], type: DataGraphEventType.doneLoading);
      }
    };

    // kick off
    _notifier.reload();

    final _dispose = graph.addListener((event) {
      if (!_notifier.mounted) {
        return;
      }

      // handle done loading
      if (_notifier.data.isLoading &&
          event.keys.last == label.toString() &&
          event.type == DataGraphEventType.doneLoading) {
        final models = _getUpdatedModels();
        _notifier.updateWith(model: models, isLoading: false, exception: null);
      }

      if (_notifier.data.isLoading == false &&
          event.type.isNode &&
          event.keys.first.startsWith(internalType)) {
        final models = _getUpdatedModels();
        log(label!, 'updated models', logLevel: 2);
        _notifier.updateWith(model: models);
      }
    });

    _notifier.onDispose = () {
      log(label!, 'disposing');
      _dispose();
    };
    return _notifier;
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
    final id = graph.getIdForKey(key);

    remote ??= _remote;
    final _maybeFinder = _internalHolder?.finders[finder]?.call(this);
    final _finder = _maybeFinder is DataFinderOne<T> ? _maybeFinder : findOne;

    // we can't use `findOne`'s default internal label
    // because we need a label to handle events
    label ??=
        DataRequestLabel('watchOne', id: key.detypify(), type: internalType);

    var _alsoWatchPairs = <List<String>>{};

    // closure to get latest model and watchable relationship pairs
    T? _getUpdatedModel({DataStateNotifier<T?>? withNotifier}) {
      final model = localAdapter.findOne(key);
      if (model != null) {
        final relationshipData = model.relationshipData;
        _alsoWatchPairs = {
          ...?alsoWatch
              ?.call(relationshipData)
              .map((dataItem) {
                final r = dataItem.instance(model);
                return r?._keys.map((key) => [r._ownerKey!, key]);
              })
              .filterNulls
              .expand((_) => _)
        };
        if (withNotifier != null) {
          model._updateNotifier(withNotifier);
        }
      } else {
        // if there is no model nothing should be watched, reset pairs
        _alsoWatchPairs = {};
      }
      return model;
    }

    final _notifier = DataStateNotifier<T?>(
      data: DataState(_getUpdatedModel(), isLoading: remote!),
    );

    log(label,
        'initializing${alsoWatch != null ? ' (with relationships)' : ''}');

    _notifier._reloadFn = () async {
      if (!_notifier.mounted || id == null) return;

      if (remote!) {
        _notifier.updateWith(isLoading: true);
      }

      final model = await _finder(
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
          if (_notifier.mounted) {
            _notifier.updateWith(isLoading: false, exception: e);
          }
          return null;
        },
      );
      // trigger doneLoading to ensure state is updated with isLoading=false
      final _key = model?._key;
      if (remote && _key != null) {
        graph._notify([_key, label.toString()],
            type: DataGraphEventType.doneLoading);
      }
    };

    // trigger local + async loading
    _notifier.reload();

    // local buffer useful to reduce amount of notifier updates
    var _model = _notifier.data.model;

    // start listening to graph for further changes
    final _dispose = graph.addListener((event) {
      if (!_notifier.mounted) return;

      final _key = _model?._key ?? key;

      // get the latest updated model with watchable relationships
      // (_alsoWatchPairs) in order to determine whether there is
      // something that will cause an event (with the introduction
      // of `andEach` even seemingly unrelated models could trigger)
      _model = _getUpdatedModel(withNotifier: _notifier);

      if (event.keys.contains(_key)) {
        // handle done loading
        if (_notifier.data.isLoading &&
            event.keys.last == label.toString() &&
            event.type == DataGraphEventType.doneLoading) {
          _notifier.updateWith(
              model: _model, isLoading: false, exception: null);
        }

        // add/update
        if (event.type == DataGraphEventType.addNode ||
            event.type == DataGraphEventType.updateNode) {
          if (_notifier.data.isLoading == false) {
            log(label!, 'added/updated node ${event.keys}', logLevel: 2);
            _notifier.updateWith(model: _model);
          }
        }

        // temporarily restore removed pair so that watchedRelationshipUpdate
        // has a chance to apply the update
        if (event.type == DataGraphEventType.removeEdge &&
            !event.keys.first.startsWith('id:')) {
          _alsoWatchPairs.add(event.keys);
        }
      }

      // handle deletion
      if (event.type == DataGraphEventType.removeNode && _model == null) {
        log(label!, 'removed node ${event.keys}', logLevel: 2);
        _notifier.updateWith(model: null);
      }

      // updates on watched relationships condition
      final watchedRelationshipUpdate = event.type.isEdge &&
          _alsoWatchPairs
              .where((pair) =>
                  pair.sorted().toString() == event.keys.sorted().toString())
              .isNotEmpty;

      // updates on watched models (of relationships) condition
      final watchedModelUpdate = event.type.isNode &&
          _alsoWatchPairs
              .where((pair) => pair.contains(event.keys.first))
              .isNotEmpty;

      // if model is loaded and any condition passes, notify update
      if (_notifier.data.isLoading == false &&
          (watchedRelationshipUpdate || watchedModelUpdate)) {
        log(label!, 'relationship update ${event.keys}', logLevel: 2);
        _notifier.updateWith(model: _model);
      }
    });

    _notifier.onDispose = () {
      log(label!, 'disposing');
      _dispose();
    };
    return _notifier;
  }
}
