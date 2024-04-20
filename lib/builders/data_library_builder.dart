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
              member.element.name!,
              DataHelpers.internalTypeFor(member.element.name!),
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
      await for (final file in b.findAssets(Glob('**/*.flutter_data.info')))
        await b.readAsString(file)
    ];

    final classes = infos.fold<List<Map<String, String>>>([], (acc, line) {
      for (final e in line.split(';')) {
        final parts = e.split('#');
        acc.add({
          'className': parts[0],
          'classNameLower': DataHelpers.internalTypeFor(parts[0]),
          'type': parts[1],
          'path': parts[2],
          'remote': parts[3],
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
            'ref.watch(${clazz['classNameLower']}AdapterProvider)'
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

    String adapterWatcherRefExtension(List<Map<String, String>> classes,
        {required bool hasWidgets}) {
      return '''
${hasWidgets ? '''
extension AdapterWidgetRefX on WidgetRef {
${classes.map((clazz) => '  Adapter<${clazz['className']}> get ${clazz['classNameLower']} => watch(${clazz['classNameLower']}AdapterProvider)..internalWatch = watch;').join('\n')}
}''' : ''}

extension AdapterRefX on ${hasWidgets ? 'Ref' : 'ProviderContainer'} {
${hasWidgets ? '' : '''
E watch<E>(ProviderListenable<E> provider) {
  return readProviderElement(provider as ProviderBase<E>).readSelf();
}
'''}
${classes.map((clazz) => '  Adapter<${clazz['className']}> get ${clazz['classNameLower']} => watch(${clazz['classNameLower']}AdapterProvider)..internalWatch = watch${hasWidgets ? ' as Watcher' : ''};').join('\n')}
}''';
    }

    //

    await b.writeAsString(
        finalAssetId,
        '''\n
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: directives_ordering, top_level_function_literal_block, depend_on_referenced_packages

import 'package:flutter_data/flutter_data.dart';
$flutterFoundationImport
$pathProviderImport
$riverpodFlutterImport

$modelImports

// ignore: prefer_function_declarations_over_variables
ConfigureAdapterLocalStorage configureAdapterLocalStorage = ({FutureFn<String>? baseDirFn, String? encryptionKey, LocalStorageClearStrategy? clear}) {
  ${isFlutter ? 'if (!kIsWeb) {' : ''}
    $autoBaseDirFn
  ${isFlutter ? '} else {' : ''}
  ${isFlutter ? '  baseDirFn ??= () => \'\';' : ''}
  ${isFlutter ? '}' : ''}
  
  return localStorageProvider.overrideWith(
    (ref) => LocalStorage(
      baseDirFn: baseDirFn,
      encryptionKey: encryptionKey,
      clear: clear,
    ),
  );
};

final adapterProviders = <String, Provider<Adapter<DataModelMixin>>>{
  ${classes.map((clazz) => '\'' + clazz['type']! + '\': ' + clazz['classNameLower']! + 'AdapterProvider').join(',\n')}
};

final adapterInitializerProvider =
  FutureProvider<AdapterInitializer>((ref) async {
${classes.map((clazz) => '    DataHelpers.setInternalType<${clazz['className']}>(\'${clazz['type']}\');').join('\n')}
    final adapters = <String, Adapter>$adaptersMap;
    final remotes = <String, bool>$remotesMap;

    await ref.read(localStorageProvider).initialize();

    // initialize and register
    for (final type in adapterProviders.keys) {
      final adapter = ref.read(adapterProviders[type]!);
      adapter.dispose();
      await adapter.initialize(
        remote: remotes[type],
        adapters: adapters,
        ref: ref
      );
      internalAdapters[type] = adapter;
    }

    return AdapterInitializer();
});
''' +
            adapterWatcherRefExtension(classes,
                hasWidgets: hasFlutterRiverpod));
  }
}
