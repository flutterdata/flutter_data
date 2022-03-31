# Changelog

## [1.3.4]

- Revamp some internal dependency management & testing pipes
- Removed `test.data.dart` (will soon add documentation to test FD-driven apps)
- Fix `Relationship` equality

## [1.3.3]

- Fix `DataModel#notifier` getter
- Fix #148 where models from local storage would be returned without relationships

## [1.3.2]

- Support Hive `LazyBox` fake in `test.data.dart`

## [1.3.0]

- Introduce API to create custom fetching and watching strategies in order to develop and reuse providers within adapters; and in this spirit, remove `Repository#watchOneNotifier` and `Repository#watchAllNotifier`
- Fix broken reload when using functional notifier extensions
- Snake case box names without breaking existing
- Ability for a model to access its `notifier`
- Fix path on Windows

## [1.2.1]

- Fix using wrong name for relationships with multiple words in local storage
- Add `relationships()` API; fix `watch()`

## [1.2.0]

- Fix issue #141 with `remote=false` by default
- Allow nullable relationships in `alsoWatch`
- Replace `dynamic` for `Object?`
- Make some `RemoteAdapter` methods public
- Notify in graph if saving with `remote=false`
- Fix issue with inverse relationships in Freezed
- Add experimental model watch API

## [1.1.1]

- Fix providers omission in test.data.dart

## [1.1.0]

- Upgrade dependencies to latest
- Simplify example app
- Fixed #125: Error when disposing repositories during tests
- Fixed #131: Allow late final relationships in models for better defaults
- Relationships are no longer collections due to upgrade in Freezed

## [1.0.1]

- Add adapter shortcuts
- Remove DataModel#watch
- Improve null deserialization handling

## [1.0.0]

- Add syntax sugar for repository methods and watchers accessible via `ref.$type`
- Add `where`/`map` functional extensions on `DataStateNotifier` (can use instead of `filterLocal` which was removed)
- Make `Relationship` a `Set` again, all `Iterable` methods available on it
- Improve relationship removal via `BelongsTo.remove()` and `HasMany.remove()`
- Upgrade Riverpod to 1.0.0 and Freezed to 1.0.0
- Fix for multiple `doneLoading` events

## [0.8.2]

- Throttle workaround, remove value notifier
- Update dependencies

## [0.8.1]

- `baseDirFn` for web bugfix
- Fix watchers dispose, remove forEach extension
- Add filterLocal and syncLocal to watchers
- Ensure model is persisted even if already initialized
- Allow bool save in DataModel `init`
- Fix minor issue serialization
- Improve tests around serialization edge cases

## [0.8.0] - 2021-06-21

- Migrate to null safety

## [0.7.2] - 2021-06-09

- Upgrade offline operations design
- Fix graph persistence issues
- Notifier `throttle` helper now takes a `Duration Function()` argument
- Make `syncLocal=false` the default
- Fix flashing screen with `filterLocal`
- Misc watcher fixes
- Update logging style

## [0.7.1] - 2021-05-27

- Offline support for all types of requests, including ad-hoc requests via `sendRequest`
- Fix `typeId` management and issues around `clear`
- Fix graph persistence issues
- Initialize graph externally (codegen)
- Remove `clearAll` (use generated `repositoryProviders` + `clear` for each one)
- Fix bugs related to `type`s, internal types
- Misc utils fixes

## [0.7.0] - 2021-04-20

- Fix singular/plural types, fix remote default
- Allow specifying remote default value via `@DataRepository`
- Allow `type` to be overridable
- Implemented offline-supporting APIs: `offlineSaved`, `offlineDeleted`, `offlineSync`, `offlineClear`
- Offline handling in `watchAll`, `watchOne` and `save`
- Fix `addInverse` issue
- Fix initialization issues
- Make relationship collection-like, rework equality, fixes #88
- Improvements to `data_state`
- Restore functional `sendRequest` API, add `E` type param
- Unify adapters into one main adapter graph and sort, closes #78
- Remove `Provider` and `GetIt` built-in support, can easily be done with documented extensions

## [0.6.3] - 2021-03-12

- Fix `test.data.dart` imports

## [0.6.2] - 2021-03-12

- Fix type issues

## [0.6.1] - 2021-03-12

- Add inverses to initialized belongsto relationships
- Support `onError` on `save`
- Notifier `updateWith` feature

## [0.6.0] - 2021-03-11

- Add `syncLocal` and `filterLocal` features
- Make `save` optimistic
- Use default headers & params by default in `sendRequest`
- Include `data_state` package within Flutter Data, upgrade others
- Fix bug with related model updates in `alsoWatch`
- Fix initialization and refresh issues
- Fix empty response handling
- Fix URI helpers broken on web

## [0.5.20] - 2020-12-06

- Allow specifying remoteType (useful for the JSON:API adapter)

## [0.5.19] - 2020-12-04

- Always return Riverpod `StateNotifierProvider`s (not `StateNotifierStateProvider`s)

## [0.5.18] - 2020-11-30

- repositoryInitializerProvider is now fully restartable via riverpod ref.container.refresh
- if can't channel error through notifier then throw

## [0.5.17] - 2020-11-16

- fix watchAll event handling

## [0.5.16] - 2020-11-13

- add testing support

## [0.5.15] - 2020-11-11

- fix onError callback
- guard onDispose with ref.mounted

## [0.5.14] - 2020-11-11

- fix faulty data_state

## [0.5.13] - 2020-11-11

- TODO since 0.5.9

## [0.5.8] - 2020-10-22

- fix clearAll

## [0.5.4] - 2020-09-28

- Upgrade dependencies
- Fix clearing boxes
- Fix `fieldForKey`/`keyForField` in attributes

## [0.5.3] - 2020-09-16

- Upgrade to Riverpod 0.10.x

## [0.5.2] - 2020-08-20

- Upgrade to Riverpod 0.6.x

## [0.5.1] - 2020-08-19

- Allow passing a repository to init() and generate dartdoc
- Expose adapter in DataModel, useful for extensions
- [bugfix] Adapter codegen related to models with a DataModel parent
- [bugfix] Type to string camelCase issue
- [internals] Simplify local storage

## [0.5.0] - 2020-07-29

- Riverpod support
- `get_it` support
- Flutter Web support
- Self-reference relationship support
- `DataSupport` is now `DataModel` and it's a mixin
- Redesign and reorganization for more API stability
- New `httpClient` and `sendRequest` for custom endpoints
- Default params & headers now called `defaultParams` and `defaultHeaders`
- JSON serializer adapter is now included by default
- Move `JSONAPIAdapter` to separate package
- Expose graph API to external adapters
- Tons of small issues fixed
- 90%+ test coverage
- Dart docs

## [0.4.2-dev.2] - 2020-06-29

- New serializer API with `DeserializedData`
- Adapt, fix & merge `StandardJSONAdapter` into core, no longer required as adapter
- New `DataSupport#init(manager, key, save)` API
- `shouldLoadRemoteAll`, `shouldLoadRemoteOne` APIs
- Misc optimizations
- Test infrastructure fixes

## [0.4.2-dev.1] - 2020-06-24

- Throttle graph events, configure duration via `throttleDuration` of `WatchAdapter`
- Namespaced graph for custom adapters wanting to leverage graph capabilities
- JSON API adapter fixes
- Removed `DataSupportMixin`: only `DataSupport` left, can be used as class or mixin
- Possible to leave models uninitialized (i.e. empty models used in forms)
- `DataSupport#save`, `DataSupport#watch`, `DataSupport#delete` will auto-initialize
- Misc fixes and vastly improved `watch*` tests

## [0.4.1] - 2020-06-18

- Stabilize API (including `data_state` upgrade)
- Ensure to reset exceptions in `watchOne` bugfix
- `DataSupportMixin` manual `init` now takes a `DataManager` argument
- Clean up and minor fixes/additions in tests

## [0.4.0] - 2020-06-15

- Flutter Data is now Adapter-based from the core
- New engine powering relationships and metadata, based on a persitent graph notifier
- Configurable inverses via `@DataRelationship`
- Notifiers and `watch`ing APIs vastly improved, `alsoWatch`, allow to work without IDs
- `DataSupport` now has `reload`, `watch`, `delete` (that can also work without IDs)
- Revamped JSON adapters; `fieldForKey` API
- De-pollute models (only carries a `_flutterDataMetadata` map)
- Remove `IdDataSupport` for Freezed, no longer needed
- Use `Set`s for relationships
- Relationships MUST be final
- Upgrade `data_state: ^0.3.0` and `json_api: ^4.2.1`, drop `rxdart`
- Massive testing improvements

## [0.3.12] - 2020-05-04

- new `repositoryFor` API, useful for serialization adapters
- JSON:API adapter includes bugfix
- `Repository#dumpLocal` to dump the contents of this repository local storage
- `Repository#remote` flag (closes #30)
- verbose flag (closes #18)
- allow passing Hive AES encryption key (closes #29)

## [0.3.11] - 2020-04-29

- new urlFor\* API
- default params (closes #27)
- normalize params/headers
- delete keys when deleting models
- minor API fixes

## [0.3.10] - 2020-04-24

- builder hotfix

## [0.3.9] - 2020-04-24

- revamped URL design
- fix API consistency
- misc fixes

## [0.3.8] - 2020-04-23

- add toJson support for different freezed kinds
- improved query parameters
- improved docs

## [0.3.7] - 2020-04-23

- fix dependency issues
- Make `json_serializable` optional
- Make type arguments in adapters optional

## [0.3.6] - 2020-04-22

- Generate `dataProviders` only if 'provider' is a dependency

## [0.3.5] - 2020-04-22

- Optional `fromJson`/`toJson`

## [0.3.4] - 2020-04-21

- Package fixes and documentation

## [0.3.2] - 2020-04-19

- Make linter and pana happy

## [0.3.1] - 2020-04-19

- Release to pub

## [0.3.0] - 2020-04-06

- Revamp serialization system
- Added standard json and JSON:API adapters
- Better relationship support

## [0.2.0] - 2020-04-04

- Auto/manual model initialization modes
- Allow nullable relationships
- Misc refactoring
- More test coverage

## [0.1.3] - 2020-04-01

- Allow `DataId` to hold `null` IDs and save ID-less models
- Fix relevant unit & integration tests

## [0.1.2] - 2020-03-31

- Fix `also` API in `DataManagerX` extension
- Improve tests

## [0.1.1] - 2020-03-31

- Initial commit
