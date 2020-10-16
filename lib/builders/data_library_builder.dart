// ignore_for_file: prefer_interpolation_to_compose_strings

import 'dart:async';

import 'package:build/build.dart';
import 'package:flutter_data/flutter_data.dart';
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

    // find contiguous graphs, independent from each other, e.g
    // IN: [{'b'}, {'a', 'b', 'c'}, {'b'}, {'a'}, {'d', 'e'}, {'f'}, {'d'}]
    // OUT: {'a,b,c', 'd,e', 'f'}
    final _gs = _classes.map((e) => e.split('#')[1].split(',').toSet());
    for (final g in _gs) {
      for (final g2 in _gs) {
        if (g != g2 && g2 != null) {
          if (g2.intersection(g).isNotEmpty) {
            g.addAll(g2);
          }
        }
      }
    }
    final graphs = _gs.map((e) => (e.toList()..sort()).join(',')).toSet();

    final classes = _classes.fold<List<Map<String, String>>>([], (acc, line) {
      for (final e in line.split(';')) {
        var parts = e.split('#');

        final graph = graphs.firstWhere((e) => e.split(',').contains(parts[0]));

        acc.add({
          'name': parts[0].singularize(),
          'related': graph,
          'path': parts[2],
        });
      }
      return acc;
    });

    // if this is a library, do not generate
    if (classes.any((c) => c['path'].startsWith('asset:'))) {
      return null;
    }

    final modelImports =
        classes.map((c) => 'import \'${c["path"]}\';').toSet().join('\n');

    var providerRegistration = '';

    final graphsMap = {
      for (final clazz in classes)
        if (clazz['related'].isNotEmpty)
          '\'${clazz['related']}\'': {
            for (final type in clazz['related'].split(','))
              '\'$type\'':
                  'ref.read(${type.singularize()}RemoteAdapterProvider)'
          }
    };

    // check dependencies

    final importPathProvider = await isDependency('path_provider', b);
    final importProvider = await isDependency('provider', b);
    final importGetIt = await isDependency('get_it', b);

    //
    var getItRegistration = '';

    if (importProvider) {
      providerRegistration = '''\n
List<SingleChildWidget> repositoryProviders({FutureFn<String> baseDirFn, List<int> encryptionKey,
    bool clear, bool remote, bool verbose}) {

  return [
    p.Provider(
        create: (_) => ProviderContainer(
          overrides: [
            configureRepositoryLocalStorage(
                baseDirFn: baseDirFn, encryptionKey: encryptionKey, clear: clear),
          ]
      ),
    ),
    p.FutureProvider<RepositoryInitializer>(
      create: (context) async {
        final init = await p.Provider.of<ProviderContainer>(context, listen: false).read(repositoryInitializerProvider(remote: remote, verbose: verbose).future);
        internalLocatorFn = (provider, context) => p.Provider.of<ProviderContainer>(context, listen: false).read(provider);
        return init;
      },
    ),''' +
          classes.map((c) => '''
    p.ProxyProvider<RepositoryInitializer, Repository<${(c['name']).capitalize()}>>(
      lazy: false,
      update: (context, i, __) => i == null ? null : p.Provider.of<ProviderContainer>(context, listen: false).read(${c['name']}RepositoryProvider),
      dispose: (_, r) => r?.dispose(),
    ),''').join('\n') +
          ']; }';
    }

    if (importGetIt) {
      getItRegistration = '''
extension GetItFlutterDataX on GetIt {
  void registerRepositories({FutureFn<String> baseDirFn, List<int> encryptionKey,
    bool clear, bool remote, bool verbose}) {
final i = GetIt.instance;

final _container = ProviderContainer(
  overrides: [
    configureRepositoryLocalStorage(baseDirFn: baseDirFn, encryptionKey: encryptionKey, clear: clear),
  ],
);

if (i.isRegistered<RepositoryInitializer>()) {
  return;
}

i.registerSingletonAsync<RepositoryInitializer>(() async {
    final init = _container.read(repositoryInitializerProvider(remote: remote, verbose: verbose).future);
    internalLocatorFn = (provider, _) => _container.read(provider);
    return init;
  });''' +
          classes.map((c) => '''
  
i.registerSingletonWithDependencies<Repository<${(c['name']).capitalize()}>>(
      () => _container.read(${c['name']}RepositoryProvider),
      dependsOn: [RepositoryInitializer]);

      ''').join('\n') +
          '} }';
    }

    final pathProviderImport = importPathProvider
        ? "import 'package:path_provider/path_provider.dart';"
        : '';

    final providerImports = importProvider
        ? [
            "import 'package:provider/provider.dart' as p hide ReadContext;",
            "import 'package:provider/single_child_widget.dart';",
          ].join('\n')
        : '';

    final getItImport =
        importGetIt ? "import 'package:get_it/get_it.dart';" : '';

    final importFlutterRiverpod = await isDependency('flutter_riverpod', b) ||
        await isDependency('hooks_riverpod', b);

    final riverpodImport = importFlutterRiverpod
        ? "import 'package:flutter/widgets.dart';\nimport 'package:flutter_riverpod/flutter_riverpod.dart';"
        : '';

    final internalLocator = importFlutterRiverpod
        ? '''
    internalLocatorFn = (provider, context) => (context as BuildContext).read(provider);
    '''
        : '';

    //

    final repoInitializeEntries = classes.map((c) => '''\n
      await ref.read(${c['name']}RepositoryProvider).initialize(
        remote: args?.remote,
        verbose: args?.verbose,
        adapters: graphs['${c['related']}'],
      );''').join('');

    final repoDisposeEntries = classes.map((c) => '''
      ref.read(${c['name']}RepositoryProvider).dispose();\n''').join('');

    await b.writeAsString(finalAssetId, '''\n
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: directives_ordering, top_level_function_literal_block

import 'package:flutter_data/flutter_data.dart';

$pathProviderImport
$providerImports
$getItImport
$riverpodImport

$modelImports

ConfigureRepositoryLocalStorage configureRepositoryLocalStorage = ({FutureFn<String> baseDirFn, List<int> encryptionKey, bool clear}) {
  // ignore: unnecessary_statements
  baseDirFn${importPathProvider ? ' ??= () => getApplicationDocumentsDirectory().then((dir) => dir.path)' : ''};
  return hiveLocalStorageProvider.overrideWithProvider(RiverpodAlias.provider(
        (_) => HiveLocalStorage(baseDirFn: baseDirFn, encryptionKey: encryptionKey, clear: clear)));
};

RepositoryInitializerProvider repositoryInitializerProvider = (
        {bool remote, bool verbose}) {
  $internalLocator
  return _repositoryInitializerProviderFamily(
      RepositoryInitializerArgs(remote, verbose));
};

final _repositoryInitializerProviderFamily =
  RiverpodAlias.futureProviderFamily<RepositoryInitializer, RepositoryInitializerArgs>((ref, args) async {
    final graphs = <String, Map<String, RemoteAdapter>>$graphsMap;
    $repoInitializeEntries

    ref.onDispose(() {
      $repoDisposeEntries
    });

    return RepositoryInitializer();
});

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
