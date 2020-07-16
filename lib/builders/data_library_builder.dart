// ignore_for_file: prefer_interpolation_to_compose_strings

import 'dart:async';

import 'package:build/build.dart';
import 'package:flutter_data/flutter_data.dart';
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:source_gen/source_gen.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:glob/glob.dart';

import 'utils.dart';

Builder dataExtensionIntermediateBuilder(options) =>
    DataExtensionIntermediateBuilder();

class DataExtensionIntermediateBuilder implements Builder {
  @override
  final buildExtensions = const {
    '.dart': ['.info']
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final resolver = buildStep.resolver;
    if (!await resolver.isLibrary(buildStep.inputId)) return;
    final lib = LibraryReader(await buildStep.inputLibrary);

    final exportAnnotation = TypeChecker.fromRuntime(DataRepository);
    final annotated = [
      for (final member in lib.annotatedWith(exportAnnotation)) member.element,
    ];

    if (annotated.isNotEmpty) {
      await buildStep.writeAsString(
          buildStep.inputId.changeExtension('.info'),
          annotated.map((element) {
            return [
              DataHelpers.getType(element.name),
              (findTypesInRelationshipGraph(element as ClassElement).toList()
                    ..sort())
                  .join(','),
              element.location.components.first
            ].join('#');
          }).join(';'));
    }
  }
}

Builder dataExtensionBuilder(options) => DataExtensionBuilder();

class DataExtensionBuilder implements Builder {
  @override
  final buildExtensions = const {
    r'$lib$': ['main.data.dart']
  };

  @override
  Future<void> build(BuildStep b) async {
    final finalAssetId = AssetId(b.inputId.package, 'lib/main.data.dart');

    final _classes = [
      await for (final file in b.findAssets(Glob('**/*.info')))
        await b.readAsString(file)
    ];

    final classes = _classes.fold<List<Map<String, String>>>([], (acc, line) {
      for (final e in line.split(';')) {
        var parts = e.split('#');
        // print(parts);
        acc.add({'name': parts[0], 'related': parts[1], 'path': parts[2]});
      }
      return acc;
    });

    final modelImports =
        classes.map((c) => 'import \'${c["path"]}\';').toSet().join('\n');

    var providerRegistration = '';

    final yaml =
        await b.readAsString(AssetId(b.inputId.package, 'pubspec.yaml'));

    final pubspec = Pubspec.parse(yaml);

    final graphs = {
      for (final clazz in classes)
        if (clazz['related'].isNotEmpty)
          '\'${clazz['related']}\'': {
            for (final type in clazz['related'].split(','))
              '\'$type\'': 'ref.read(${type}RemoteAdapterProvider)'
          }
    };

    // check if `path_provider` is a dependency
    final importPathProvider =
        pubspec.dependencies.keys.any((key) => key == 'path_provider');

    // check if `provider` is a dependency
    final importProvider =
        pubspec.dependencies.keys.any((key) => key == 'provider');

    // check if `get_it` is a dependency
    final importGetIt = pubspec.dependencies.keys.any((key) => key == 'get_it');
    var getItRegistration = '';

    if (importProvider) {
      providerRegistration = '''\n
class RepositoryInitializer extends ValueNotifier<bool> {
  RepositoryInitializer(bool value) : super(value);
  bool get isLoading => !value;
}

List<SingleChildWidget> repositoryProviders({FutureOr<String> Function() baseDirFn,
    bool clear, bool remote, bool verbose, List<int> encryptionKey, FutureProvider<void> alsoInitialize}) {
  final _owner = ProviderStateOwner(overrides: [
    hiveDirectoryProvider.overrideAs(FutureProvider((ref) {
      final dir = baseDirFn?.call();
      return dir${importPathProvider ? ' ?? getApplicationDocumentsDirectory().then((dir) => dir.path)' : ''};
    })),
    hiveLocalStorageProvider.overrideAs(Provider(
        (ref) => HiveLocalStorage(ref, encryptionKey: encryptionKey, clear: true)))
  ]);
  return [
    p.ChangeNotifierProvider<RepositoryInitializer>(
      create: (_) {
        final notifier = RepositoryInitializer(false);
        initializeRepositories(_owner.ref,
                remote: remote, verbose: verbose, alsoInitialize: alsoInitialize)
            .then((_) => notifier.value = true);
        return notifier;
      },
    ),''' +
          classes.map((c) => '''
    p.ProxyProvider<RepositoryInitializer, Repository<${(c['name']).singularize().capitalize()}>>(
      lazy: false,
      update: (_, i, __) => i.isLoading ? null : _owner.ref.read(${c['name']}RepositoryProvider),
      dispose: (_, r) => r?.dispose(),
    ),''').join('\n') +
          ']; }';
    }

    if (importGetIt) {
      getItRegistration = '''
class _RepositoryInitializer {}

extension GetItFlutterDataX on GetIt {
  void registerRepositories({FutureOr<String> Function() baseDirFn,
    bool clear, bool remote, bool verbose, List<int> encryptionKey}) {
final i = debugGlobalServiceLocatorInstance = GetIt.instance;

final _owner = ProviderStateOwner(overrides: [
    hiveDirectoryProvider.overrideAs(FutureProvider((ref) async {
      final dir = baseDirFn?.call();
      return dir${importPathProvider ? ' ?? getApplicationDocumentsDirectory().then((dir) => dir.path)' : ''};
    })),
    hiveLocalStorageProvider.overrideAs(Provider(
        (ref) => HiveLocalStorage(ref, encryptionKey: encryptionKey, clear: true)))
  ]);

i.registerSingletonAsync<_RepositoryInitializer>(() async {
    await initializeRepositories(_owner.ref, remote: remote, verbose: verbose);
    return _RepositoryInitializer();
  });''' +
          classes.map((c) => '''
  
i.registerSingletonWithDependencies<Repository<${(c['name']).singularize().capitalize()}>>(
      () => _owner.ref.read(${c['name']}RepositoryProvider),
      dependsOn: [_RepositoryInitializer]);

      ''').join('\n') +
          '} }';
    }

    final pathProviderImport = importPathProvider
        ? "import 'package:path_provider/path_provider.dart';"
        : '';

    final providerImports = importProvider
        ? [
            "import 'package:provider/provider.dart' as p;",
            "import 'package:provider/single_child_widget.dart';",
            "import 'package:flutter/foundation.dart';"
          ].join('\n')
        : '';

    final getItImport =
        importGetIt ? "import 'package:get_it/get_it.dart';" : '';

    //

    final repoEntries = classes.map((c) => '''
            await ref.read(${c['name']}RepositoryProvider).initialize(
              remote: remote,
              verbose: verbose,
              adapters: graphs['${c['related']}'],
            );''').join('');

    await b.writeAsString(finalAssetId, '''\n
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: directives_ordering, top_level_function_literal_block

import 'dart:async';
import 'package:flutter_data/flutter_data.dart';

$pathProviderImport
$providerImports
$getItImport

$modelImports

Future<void> initializeRepositories(ProviderReference ref,
    {bool remote, bool verbose, FutureProvider<void> alsoInitialize}) async {
    final graphs = <String, Map<String, RemoteAdapter>>$graphs;
    $repoEntries
    if (alsoInitialize != null) {
      await ref.read(alsoInitialize);
    }
}

StateNotifierProvider<RepositoryInitializerNotifier>
    repositoryInitializerProvider(
        {bool remote, bool verbose, FutureProvider<void> alsoInitialize}) {
  return StateNotifierProvider<RepositoryInitializerNotifier>((ref) {
    final notifier = RepositoryInitializerNotifier(false);
    initializeRepositories(ref,
            remote: remote, verbose: verbose, alsoInitialize: alsoInitialize)
        .then((_) => notifier.value = true);
    return notifier;
  });
}

$providerRegistration

$getItRegistration
''');
  }
}

Set<String> findTypesInRelationshipGraph(ClassElement elem,
    [Set<String> result]) {
  return relationshipFields(elem)
      .fold<Set<String>>(result ?? {DataHelpers.getType(elem.name)}, (acc, f) {
    var type = DataHelpers.getType(f.typeElement.name);
    if (!acc.contains(type)) {
      acc.add(type);
      acc.addAll(findTypesInRelationshipGraph(f.typeElement, acc));
    }
    return acc;
  });
}
