## [0.4.1] - 2020-06-18
 
 - stabilize API (including `data_state` upgrade)
 - ensure to reset exceptions in `watchOne` bugfix
 - `DataSupportMixin` manual `init` now takes a `DataManager` argument
 - clean up and minor fixes/additions in tests

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

  - new urlFor* API
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