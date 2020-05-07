// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:build/build.dart';
import 'package:flutter_data/flutter_data.dart';
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:source_gen/source_gen.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:glob/glob.dart';

Builder repositoryBuilder(options) =>
    SharedPartBuilder([DataGenerator()], 'data');

class DataGenerator extends GeneratorForAnnotation<DataRepository> {
  @override
  String generateForAnnotatedElement(element, annotation, buildStep) {
    final type = element.name;

    if (element is! ClassElement) {
      throw UnsupportedError(
          "Can't generate repository for $type. Please use @DataRepository on a model class.");
    }

    final classElement = element as ClassElement;

    var _mutableClassElement = classElement;
    var isFinal = true;

    while (_mutableClassElement != null &&
        (isFinal = _mutableClassElement.getSetter('id') == null)) {
      if (!isFinal) {
        break;
      }
      _mutableClassElement = _mutableClassElement.supertype?.element;
    }

    if (!isFinal) {
      throw UnsupportedError(
          "Can't generate repository for $type. Its `id` field MUST be final");
    }

    // unique collection of constructor arguments and fields
    final fieldSet = {
      ...classElement.constructors.map((e) => e.parameters).expand((i) => i),
      ...classElement.fields
    };

    List<String> getRelationshipsFor(String kind) =>
        fieldSet.fold([], (result, field) {
          if (field.type.element.name == kind &&
              field.type is ParameterizedType) {
            final typeParameterName = (field.type as ParameterizedType)
                .typeArguments
                .first
                .element
                .name;
            var value =
                '${field.name}#${DataId.getType(typeParameterName)}#$kind#$typeParameterName';
            if (!result.contains(value)) {
              result.add(value);
            }
          }
          return result;
        });

    //

    Map<String, String> _prepareMeta(list) {
      return {for (var e in list) '\'${e[0]}\'': '\'${e[1]}\''};
    }

    final hasManys = getRelationshipsFor('HasMany').map((s) => s.split('#'));
    final belongsTos =
        getRelationshipsFor('BelongsTo').map((s) => s.split('#'));
    final all = [...hasManys, ...belongsTos];

    final relationshipMetadata = <String, dynamic>{
      '\'HasMany\'': _prepareMeta(hasManys),
      '\'BelongsTo\'': _prepareMeta(belongsTos),
    };

    final additionalRepos = annotation
        .read('repositoryFor')
        .listValue
        .map((e) => ['_', e.toTypeValue().toString()]);

    final repositoryFors = [...all, ...additionalRepos].asMap().map((_, t) {
      final type = DataId.getType(t.last);
      return MapEntry('\'$type\'', 'manager.locator<Repository<${t.last}>>()');
    });

    //

    final deserialize = all.map((t) {
      final name = t.first;
      return '''map['$name'] = { '_': [map['$name'], manager] };''';
    }).join('\n');

    final serialize = all.map((t) {
      final name = t.first;
      return '''map['$name'] = model.$name?.toJson();''';
    }).join('\n');

    final hasFromJson =
        classElement.constructors.any((c) => c.name == 'fromJson');
    final fromJson = hasFromJson
        ? '$type.fromJson(map as Map<String, dynamic>)'
        : '_\$${type}FromJson(map as Map<String, dynamic>)';

    final methods = [
      ...classElement.methods,
      ...classElement.interfaces.map((i) => i.methods).expand((i) => i),
      ...classElement.mixins.map((i) => i.methods).expand((i) => i)
    ];
    final hasToJson = methods.any((c) => c.name == 'toJson');
    final toJson = hasToJson ? 'model.toJson()' : '_\$${type}ToJson(model)';

    //

    final setOwnerInRelationships = all.map((t) {
      final name = t.first, localType = t.last;
      return '''model.$name?.owner = owner;''';
    }).join('\n');

    final setInverseInModel = all.map((t) {
      final name = t.first, localType = t.last;
      return '''if (inverse is DataId<$localType>) { model.$name?.inverse = inverse; }''';
    }).join('\n');

    // mixins

    final additionalMixins = annotation.read('adapters').listValue.map((o) {
      var hasTypeArgument = false;
      final mixinType = o.toTypeValue();
      if (mixinType is ParameterizedType) {
        final args = mixinType.typeArguments;
        assert(args.length > 1,
            'At most one type argument is supported for $mixinType');
        hasTypeArgument = args.length == 1;
      }
      return '${mixinType.element.name}${hasTypeArgument ? "<$type>" : ""}';
    });

    final mixins = [
      '_\$${type}ModelAdapter',
      'RemoteAdapter<$type>',
      'WatchAdapter<$type>',
      ...additionalMixins
    ];

    // main

    return '''
// ignore_for_file: unused_local_variable
// ignore_for_file: always_declare_return_types
mixin _\$${type}ModelAdapter on Repository<$type> {

  @override
  get relationshipMetadata => $relationshipMetadata;

  @override
  Repository repositoryFor(String type) {
    return <String, Repository>$repositoryFors[type];
  } 

  @override
  deserialize(map, {key, initialize = true}) {
    $deserialize
    return $fromJson;
  }

  @override
  serialize(model) {
    final map = $toJson;
    $serialize
    return map;
  }

  @override
  setOwnerInRelationships(owner, model) {
    $setOwnerInRelationships
  }

  @override
  void setInverseInModel(inverse, model) {
    $setInverseInModel
  }
}

class \$${type}Repository = Repository<$type> with ${mixins.join(', ')};

''';
  }
}

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
      for (var member in lib.annotatedWith(exportAnnotation)) member.element,
    ];
    if (annotated.isNotEmpty) {
      await buildStep.writeAsString(
          buildStep.inputId.changeExtension('.info'),
          annotated
              .map((e) => '${e.name}#${e.location.components.first}')
              .join(','));
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
      await for (var file in b.findAssets(Glob('**/*.info')))
        await b.readAsString(file)
    ];

    final classes = _classes.fold<List<Map<String, String>>>([], (acc, line) {
      for (var e in line.split(',')) {
        var parts = e.split('#');
        acc.add({'name': parts[0], 'path': parts[1]});
      }
      return acc;
    });

    // NOTE: can't include "exports" (model re-exports)
    // because if used (generated file imported in codebase)
    // it will subsequently cause wrong type information
    // in the data builder

    final modelImports =
        classes.map((c) => 'import \'${c["path"]}\';').toSet().join('\n');

    var provider = '';

    final yaml =
        await b.readAsString(AssetId(b.inputId.package, 'pubspec.yaml'));

    var pubspec = Pubspec.parse(yaml);

    // is provider a dependency?
    var importProvider =
        pubspec.dependencies.keys.any((key) => key == 'provider');

    if (importProvider) {
      provider = '''\n
List<SingleChildWidget> dataProviders(Future<Directory> Function() directory, {bool clear, bool remote, bool verbose, List<int> encryptionKey}) => [
  FutureProvider<DataManager>(
    create: (_) => directory().then((dir) {
          return FlutterData.init(dir, clear: clear, remote: remote, verbose: verbose, encryptionKey: encryptionKey);
        })),
''' +
          classes.map((c) => '''\n
    ProxyProvider<DataManager, Repository<${c['name']}>>(
      lazy: false,
      update: (_, m, __) => m?.locator<Repository<${c['name']}>>(),
    ),''').join('\n') +
          '];';
    }

    var out = '''\n
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: directives_ordering

import 'dart:io';
import 'package:flutter_data/flutter_data.dart';
${importProvider ? "import 'package:provider/provider.dart';\nimport 'package:provider/single_child_widget.dart';" : ""}

$modelImports

extension FlutterData on DataManager {

  static Future<DataManager> init(Directory baseDir, {bool autoModelInit = true, bool clear, bool remote, bool verbose, List<int> encryptionKey, Function(void Function<R>(R)) also}) async {
    assert(baseDir != null);

    final injection = DataServiceLocator();

    final manager = await DataManager(autoModelInit: autoModelInit).init(baseDir, injection.locator, clear: clear, verbose: verbose);
    injection.register(manager);

''' +
        classes.map((c) => '''
    final ${c['name'].toLowerCase()}Box = await Repository.getBox<${c['name']}>(manager, encryptionKey: encryptionKey);
    final ${c['name'].toLowerCase()}Repository = \$${c['name']}Repository(manager, ${c['name'].toLowerCase()}Box, remote: remote, verbose: verbose);
    injection.register<Repository<${c['name']}>>(${c['name'].toLowerCase()}Repository);
''').join('\n') +
        '''\n
    if (also != null) {
      // ignore: unnecessary_lambdas
      also(<R>(R obj) => injection.register<R>(obj));
    }

    return manager;

  }
  
}

$provider
''';

    await b.writeAsString(finalAssetId, out);
  }
}
