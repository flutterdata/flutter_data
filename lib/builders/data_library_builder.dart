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
              element.name,
              element.location.components.first,
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
        final parts = e.split('#');
        final type = DataHelpers.getType(parts[0]);
        acc.add({
          'name': parts[0],
          'type': type,
          'singularType': type.singularize(),
          'path': parts[1]
        });
      }
      return acc;
    })
      ..sort((a, b) => a['type'].compareTo(b['type']));

    // if this is a library, do not generate
    if (classes.any((clazz) => clazz['path'].startsWith('asset:'))) {
      return null;
    }

    final modelImports = classes
        .map((clazz) => 'import \'${clazz['path']}\';')
        .toSet()
        .join('\n');

    var providerRegistration = '';

    final graphMap = {
      for (final clazz in classes)
        '\'${clazz['type']}\'':
            'ref.read(${clazz['singularType']}RemoteAdapterProvider)'
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
        return await p.Provider.of<ProviderContainer>(context, listen: false).read(repositoryInitializerProvider(remote: remote, verbose: verbose).future);
      },
    ),''' +
          classes.map((clazz) => '''
    p.ProxyProvider<RepositoryInitializer, Repository<${clazz['name']}>>(
      lazy: false,
      update: (context, i, __) => i == null ? null : p.Provider.of<ProviderContainer>(context, listen: false).read(${clazz['singularType']}RepositoryProvider),
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
    internalLocatorFn =
          <T extends DataModel<T>>(ProviderBase<Object, Repository<T>> provider, _) =>
              _container.read(provider);
    return init;
  });''' +
          classes.map((clazz) => '''
  
i.registerSingletonWithDependencies<Repository<${clazz['name']}>>(
      () => _container.read(${clazz['singularType']}RepositoryProvider),
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
        ? "import 'package:flutter_riverpod/flutter_riverpod.dart';"
        : '';

    //

    final repoInitializeEntries = classes.map((clazz) => '''\n
      final _${clazz['singularType']}Repository = ref.read(${clazz['singularType']}RepositoryProvider);
      _${clazz['singularType']}Repository.dispose();
      await _${clazz['singularType']}Repository.initialize(
        remote: args?.remote,
        verbose: args?.verbose,
        adapters: adapters,
      );''').join('');

    final repoDisposeEntries = classes
        .map((clazz) => '''
      ref.read(${clazz['singularType']}RepositoryProvider).dispose();\n''')
        .join('');

    await b.writeAsString(finalAssetId, '''\n
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: directives_ordering, top_level_function_literal_block

import 'package:flutter_data/flutter_data.dart';

$pathProviderImport
$providerImports
$getItImport
$riverpodImport

$modelImports

// ignore: prefer_function_declarations_over_variables
ConfigureRepositoryLocalStorage configureRepositoryLocalStorage = ({FutureFn<String> baseDirFn, List<int> encryptionKey, bool clear}) {
  // ignore: unnecessary_statements
  baseDirFn${importPathProvider ? ' ??= () => getApplicationDocumentsDirectory().then((dir) => dir.path)' : ''};
  return hiveLocalStorageProvider.overrideWithProvider(Provider(
        (_) => HiveLocalStorage(baseDirFn: baseDirFn, encryptionKey: encryptionKey, clear: clear)));
};

// ignore: prefer_function_declarations_over_variables
RepositoryInitializerProvider repositoryInitializerProvider = (
        {bool remote, bool verbose}) {
  return _repositoryInitializerProviderFamily(
      RepositoryInitializerArgs(remote, verbose));
};

final _repositoryInitializerProviderFamily =
  FutureProvider.family<RepositoryInitializer, RepositoryInitializerArgs>((ref, args) async {
    final adapters = <String, RemoteAdapter>$graphMap;
    $repoInitializeEntries

    ref.onDispose(() {
      if (ref.mounted) {
        $repoDisposeEntries
      }
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
