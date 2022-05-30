part of flutter_data;

class IsarLocalStorage {
  IsarLocalStorage({
    this.baseDirFn,
    bool? clear,
  }) : clear = clear ?? false;

  final FutureOr<String> Function()? baseDirFn;
  final bool clear;
  late final String path;

  Isar? _isar;

  Future<void> initialize(Iterable<RemoteAdapter> adapters) async {
    if (_isar != null) return;

    if (baseDirFn == null) {
      throw UnsupportedError('''
A base directory path MUST be supplied to
the hiveLocalStorageProvider via the `baseDirFn`
callback.

In Flutter, `baseDirFn` will be supplied automatically if
the `path_provider` package is in `pubspec.yaml` AND
Flutter Data is properly configured:

Did you supply the override?

Widget build(context) {
  return ProviderContainer(
    overrides: [
      configureRepositoryLocalStorage()
    ],
    child: MaterialApp(
''');
    }

    path = await baseDirFn!();

    _isar = Isar.getInstance('flutter_data') ??
        await Isar.open(
          name: 'flutter_data',
          schemas: [
            for (final adapter in adapters)
              (adapter.localAdapter as IsarLocalAdapter).schema,
          ],
          directory: path,
          // inspector: true,
        );
    if (clear) _isar!.writeTxnSync(() => _isar!.clearSync());
  }
}

final isarLocalStorageProvider =
    Provider<IsarLocalStorage>((ref) => throw UnimplementedError());
