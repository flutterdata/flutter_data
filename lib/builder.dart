// ignore_for_file: prefer_interpolation_to_compose_strings

import 'dart:convert';

import 'package:build/build.dart';
import 'package:flutter_data/flutter_data.dart';
import 'package:source_gen/source_gen.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

import 'package:glob/glob.dart';

import 'annotations.dart';

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

    List<String> getRelationshipsFor(String kind) =>
        classElement.constructors.fold([], (result, constructor) {
          for (var field in constructor.parameters) {
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
          }
          return result;
        });

    //

    _prepareMeta(list) {
      return {for (var e in list) e[0]: e[1]};
    }

    final hasManys = getRelationshipsFor('HasMany').map((s) => s.split('#'));
    final belongsTos =
        getRelationshipsFor('BelongsTo').map((s) => s.split('#'));

    final relationshipMetadata = json.encode({
      'HasMany': _prepareMeta(hasManys),
      'BelongsTo': _prepareMeta(belongsTos),
    });

    final deserializeHasMany = hasManys.map((t) {
      final name = t.first, localType = t.last;
      return '''map['$name'] = { 'HasMany': HasMany<$localType>.fromToMany(map['$name'], manager, included: included) };''';
    }).join('\n');

    final deserializeBelongsTo = belongsTos.map((t) {
      final name = t.first, localType = t.last;
      return '''map['$name'] = { 'BelongsTo': BelongsTo<$localType>.fromToOne(map['$name'], manager, included: included) };''';
    }).join('\n');

    final serializeHasMany = hasManys.map((t) {
      final name = t.first;
      return ''''$name': model.$name?.toMany,''';
    }).join('\n');

    final serializeBelongsTo = belongsTos.map((t) {
      final name = t.first;
      return ''''$name': model.$name?.toOne,''';
    }).join('\n');

    final removeRelationshipsFromAttributes =
        [...hasManys, ...belongsTos].map((t) {
      return '''map.remove('${t.first}');''';
    }).join('\n');

    final relationshipsInConstructor =
        '$serializeHasMany$serializeBelongsTo' == "" ? "null" : "relationships";

    final localDeserializeHasMany = hasManys.map((t) {
      final name = t.first, localType = t.last;
      return '''map['$name'] = { 'HasMany': HasMany<$localType>.fromKeys(map['$name'], manager) };''';
    }).join('\n');

    final localDeserializeBelongsTo = belongsTos.map((t) {
      final name = t.first, localType = t.last;
      return '''map['$name'] = { 'BelongsTo': BelongsTo<$localType>.fromKey(map['$name'], manager) };''';
    }).join('\n');

    final localSerializeHasMany = hasManys.map((t) {
      final name = t.first;
      return '''map['$name'] = model.$name?.keys;''';
    }).join('\n');

    final localSerializeBelongsTo = belongsTos.map((t) {
      final name = t.first;
      return '''map['$name'] = model.$name?.key;''';
    }).join('\n');

    final setOwnerInRelationships = [...hasManys, ...belongsTos].map((t) {
      final name = t.first, localType = t.last;
      return '''model.$name?.owner = owner;''';
    }).join('\n');

    final setOwnerInModel = [...hasManys, ...belongsTos].map((t) {
      final name = t.first, localType = t.last;
      return '''if (owner is DataId<$localType>) { model.$name?.owner = owner; }''';
    }).join('\n');

    // mixins

    final mixins = annotation.read('mixins').listValue.map((o) {
      return '${o.toTypeValue().element.name}<$type>';
    });

    var mixinsString = '';
    if (mixins.isNotEmpty) {
      mixinsString = 'with ${mixins.join(', ')}';
    }

    // main

    return '''
// ignore_for_file: unused_local_variable
class _\$${type}Repository extends Repository<$type> {
  _\$${type}Repository(LocalAdapter<$type> adapter) : super(adapter);

  @override
  Map<String, dynamic> get relationshipMetadata => $relationshipMetadata;

  @override
  $type internalDeserialize(obj, { withKey, included }) {
    var map = <String, dynamic>{
      ...?obj?.relationships
    };
    
    $deserializeHasMany
    $deserializeBelongsTo
    
    var dataId = manager.dataId<$type>(obj.id, key: withKey);
    return $type.fromJson({
      ...{'id': dataId.id},
      ...obj.attributes,
      ...map,
    });
  }

  @override
  internalSerialize($type model) {
    var relationships = {
      $serializeHasMany
      $serializeBelongsTo
    };

    final map = model.toJson();
    final dataId = manager.dataId<$type>(model.id);

    map.remove('id');
    $removeRelationshipsFromAttributes

    return DataResourceObject(
      dataId.type,
      dataId.id,
      attributes: map,
      relationships: $relationshipsInConstructor,
    );
  }

  @override
  void setOwnerInRelationships(DataId<$type> owner, $type model) {
    $setOwnerInRelationships
  }

  @override
  void setOwnerInModel(DataId owner, $type model) {
    $setOwnerInModel
  }
}

class \$${type}Repository extends _\$${type}Repository $mixinsString {
  \$${type}Repository(LocalAdapter<$type> adapter) : super(adapter);
}

// ignore: must_be_immutable, unused_local_variable
class \$${type}LocalAdapter extends LocalAdapter<$type> {
  \$${type}LocalAdapter(box, DataManager manager) : super(box, manager);

  @override
  $type internalLocalDeserialize(map) {
    map = fixMap(map);

    $localDeserializeHasMany
    $localDeserializeBelongsTo
    
    return $type.fromJson(map);
  }

  @override
  Map<String, dynamic> internalLocalSerialize($type model) {
    var map = model.toJson();
    $localSerializeHasMany
    $localSerializeBelongsTo
    return map;
  }
}''';
  }
}

Builder dataExtensionIntermediateBuilder(options) =>
    DataExtensionIntermediateBuilder();

class DataExtensionIntermediateBuilder implements Builder {
  @override
  final buildExtensions = const {
    '.dart': ['.info']
  };

  bool isProvider = false;

  @override
  Future<void> build(BuildStep buildStep) async {
    final resolver = buildStep.resolver;
    if (!await resolver.isLibrary(buildStep.inputId)) return;
    final lib = LibraryReader(await buildStep.inputLibrary);
    if (!isProvider) {
      isProvider = lib.element.importedLibraries.any((e) {
        return e.librarySource.fullName.startsWith('/provider/');
      });
    }

    final exportAnnotation = TypeChecker.fromRuntime(DataRepository);
    final annotated = [
      for (var member in lib.annotatedWith(exportAnnotation)) member.element,
    ];
    if (annotated.isNotEmpty) {
      await buildStep.writeAsString(
          buildStep.inputId.changeExtension('.info'),
          annotated
              .map(
                  (e) => '${e.name}#${e.location.components.first}#$isProvider')
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
    var importProvider = false;
    final finalAssetId = AssetId(b.inputId.package, 'lib/main.data.dart');
    final _classes = [
      await for (var file in b.findAssets(Glob('**/*.info')))
        await b.readAsString(file)
    ];

    final classes = _classes.fold<List<Map<String, String>>>([], (acc, line) {
      for (var e in line.split(',')) {
        var parts = e.split('#');
        if (!importProvider) {
          importProvider = parts[2] == 'true';
        }
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

    String provider = "";
    String provider2 = "";

    if (importProvider) {
      provider = '''
List<SingleChildWidget> get providers {
  return [
    ${classes.map((c) => 'Provider<Repository<' + c['name'] + '>>.value(value: locator<Repository<' + c['name'] + '>>()),').join('\n')}
  ];
}
''';

      provider2 = '''\n
List<SingleChildWidget> dataProviders(Future<Directory> Function() directory, {bool clear = true}) => [
  FutureProvider<DataManager>(
    create: (_) => directory().then((dir) {
          return FlutterData.init(dir, clear: clear);
        })),
''' +
          classes.map((c) => '''\n
    ProxyProvider<DataManager, Repository<${c['name']}>>(
      lazy: false,
      update: (_, m, __) => m?.locator<Repository<${c['name']}>>(),
    ),''').join('\n') +
          '];';
    }

    String out = '''\n
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: directives_ordering

import 'dart:io';
import 'package:flutter_data/flutter_data.dart';
${importProvider ? "import 'package:provider/provider.dart';\nimport 'package:provider/single_child_widget.dart';" : ""}

$modelImports

extension FlutterData on DataManager {

  static Future<DataManager> init(Directory baseDir, {bool autoModelInit = true, bool clear = true, Function(void Function<R>(R)) also}) async {
    assert(baseDir != null);

    final injection = DataServiceLocator();

    final manager = await DataManager(autoModelInit: autoModelInit).init(baseDir, injection.locator, clear: clear);
    injection.register(manager);
''' +
        classes.map((c) => '''
    final ${c['name'].toLowerCase()}LocalAdapter = await manager.initAdapter<${c['name']}>(clear, (box) => \$${c['name']}LocalAdapter(box, manager));
    injection.register(${c['name'].toLowerCase()}LocalAdapter);
    injection.register<Repository<${c['name']}>>(\$${c['name']}Repository(${c['name'].toLowerCase()}LocalAdapter));
''').join('\n') +
        '''\n
    if (also != null) {
      // ignore: unnecessary_lambdas
      also(<R>(R obj) => injection.register<R>(obj));
    }

    return manager;

}

  $provider
  
}

$provider2
''';

    await b.writeAsString(finalAssetId, out);
  }
}
