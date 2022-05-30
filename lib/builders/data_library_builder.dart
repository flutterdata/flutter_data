// ignore_for_file: prefer_interpolation_to_compose_strings

import 'dart:async';

import 'package:build/build.dart';
import 'package:flutter_data/flutter_data.dart';
import 'package:glob/glob.dart';
import 'package:source_gen/source_gen.dart';

import 'utils.dart';

Builder dataExtensionIntermediateBuilder(options) =>
    DataExtensionIntermediateBuilder();

class DataExtensionIntermediateBuilder implements Builder {
  @override
  final buildExtensions = const {
    '.dart': ['.flutter_data.info']
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final resolver = buildStep.resolver;
    if (!await resolver.isLibrary(buildStep.inputId)) return;
    final lib = LibraryReader(await buildStep.inputLibrary);

    final annotation = TypeChecker.fromRuntime(DataRepository);
    final members = [
      for (final member in lib.annotatedWith(annotation)) member,
    ];

    if (members.isNotEmpty) {
      await buildStep.writeAsString(
          buildStep.inputId.changeExtension('.flutter_data.info'),
          members.map((member) {
            return [
              member.element.name,
              member.element.location!.components.first,
              member.annotation.read('remote').boolValue,
            ].join('#');
          }).join(';'));
    }
  }
}

Builder dataExtensionBuilder(options) => DataExtensionBuilder();

class DataExtensionBuilder implements Builder {
  @override
  final buildExtensions = const {
    r'$lib$': ['main.data.dart'],
  };

  @override
  Future<void> build(BuildStep b) async {
    final finalAssetId = AssetId(b.inputId.package, 'lib/main.data.dart');

    final infos = [
      await for (final file in b.findAssets(Glob('**/*.info')))
        await b.readAsString(file)
    ];

    final classes = infos.fold<List<Map<String, String>>>([], (acc, line) {
      for (final e in line.split(';')) {
        final parts = e.split('#');
        final type = DataHelpers.getType(parts[0]);
        acc.add({
          'name': parts[0],
          'type': type,
          'path': parts[1],
          'remote': parts[2],
        });
      }
      return acc;
    })
      ..sort((a, b) => a['type']!.compareTo(b['type']!));

    // if this is a library, do not generate
    if (classes.any((clazz) => clazz['path']!.startsWith('asset:'))) {
      return;
    }

    final modelImports = classes
        .map((clazz) => 'import \'${clazz['path']}\';')
        .toSet()
        .join('\n');

    final adaptersMap = {
      for (final clazz in classes)
        '\'${clazz['type']}\'':
            'ref.watch(internal${clazz['type'].toString().capitalize()}RemoteAdapterProvider)'
    };

    final remotesMap = {
      for (final clazz in classes) '\'${clazz['type']}\'': clazz['remote']
    };

    // imports

    final isFlutter = await isDependency('flutter', b);
    final hasPathProvider = await isDependency('path_provider', b);
    final hasFlutterRiverpod = await isDependency('flutter_riverpod', b) ||
        await isDependency('hooks_riverpod', b);

    final flutterFoundationImport = isFlutter
        ? "import 'package:flutter/foundation.dart' show kIsWeb;"
        : '';
    final pathProviderImport = hasPathProvider
        ? "import 'package:path_provider/path_provider.dart';"
        : '';
    final riverpodFlutterImport = hasFlutterRiverpod
        ? "import 'package:flutter_riverpod/flutter_riverpod.dart';"
        : '';

    final autoBaseDirFn = hasPathProvider
        ? 'baseDirFn ??= () => getApplicationDocumentsDirectory().then((dir) => dir.path);'
        : '';

    //

    String repositoryWatcherRefExtension(List<Map<String, String>> classes,
        {required bool hasWidgets}) {
      return '''
${hasWidgets ? '''
extension RepositoryWidgetRefX on WidgetRef {
${classes.map((clazz) => '  Repository<${clazz['name']}> get ${clazz['type']} => watch(${clazz['type']}RepositoryProvider)..remoteAdapter.internalWatch = watch;').join('\n')}
}''' : ''}

extension RepositoryRefX on ${hasWidgets ? 'Ref' : 'ProviderContainer'} {
${hasWidgets ? '' : '''
E watch<E>(ProviderListenable<E> provider) {
  return readProviderElement(provider as ProviderBase<E>).readSelf();
}
'''}
${classes.map((clazz) => '  Repository<${clazz['name']}> get ${clazz['type']} => watch(${clazz['type']}RepositoryProvider)..remoteAdapter.internalWatch = watch${hasWidgets ? ' as Watcher' : ''};').join('\n')}
}''';
    }

    //

    await b.writeAsString(
        finalAssetId,
        '''\n
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: directives_ordering, top_level_function_literal_block

import 'package:flutter_data/flutter_data.dart';
$flutterFoundationImport
$pathProviderImport
$riverpodFlutterImport

$modelImports

// ignore: prefer_function_declarations_over_variables
ConfigureRepositoryLocalStorage configureRepositoryLocalStorage = ({FutureFn<String>? baseDirFn, List<int>? encryptionKey, bool? clear}) {
  ${isFlutter ? 'if (!kIsWeb) {' : ''}
    $autoBaseDirFn
  ${isFlutter ? '} else {' : ''}
  ${isFlutter ? '  baseDirFn ??= () => \'\';' : ''}
  ${isFlutter ? '}' : ''}
  
  return isarLocalStorageProvider
      .overrideWithProvider(Provider((ref) => IsarLocalStorage(
            baseDirFn: baseDirFn,
            clear: clear,
          )));
};

final repositoryProviders = <String, Provider<Repository<DataModel>>>{
  ${classes.map((clazz) => '\'' + clazz['type']! + '\': ' + clazz['type']! + 'RepositoryProvider').join(',\n')}
};

final repositoryInitializerProvider =
  FutureProvider<RepositoryInitializer>((ref) async {
    final adapters = <String, RemoteAdapter>$adaptersMap;
    final remotes = <String, bool>$remotesMap;

    await ref.watch(graphNotifierProvider).initialize();

    // initialize and register
    for (final type in repositoryProviders.keys) {
      final repository = ref.read(repositoryProviders[type]!);
      repository.dispose();
      await repository.initialize(
        remote: remotes[type],
        adapters: adapters,
      );
      internalRepositories[type] = repository;
    }

    // deferred model initialization
    for (final repository in internalRepositories.values) {
      await repository.remoteAdapter.internalInitializeModels();
    }

    return RepositoryInitializer();
});
''' +
            repositoryWatcherRefExtension(classes,
                hasWidgets: hasFlutterRiverpod));
  }
}
