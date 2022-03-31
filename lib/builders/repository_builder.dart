// ignore_for_file: prefer_interpolation_to_compose_strings

import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:flutter_data/flutter_data.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:source_gen/source_gen.dart';

import 'utils.dart';

Builder repositoryBuilder(options) =>
    SharedPartBuilder([RepositoryGenerator()], 'repository');

class RepositoryGenerator extends GeneratorForAnnotation<DataRepository> {
  @override
  Future<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) async {
    final classType = element.name;
    final typeLowerCased = DataHelpers.getType(classType);
    ClassElement classElement;

    try {
      classElement = element as ClassElement;
    } catch (e) {
      throw UnsupportedError(
          "Can't generate repository for $classType. Please use @DataRepository on a class.");
    }

    void _checkIsFinal(final ClassElement? element, String? name) {
      if (element != null) {
        if (name != null &&
            element.getSetter(name) != null &&
            !element.getField(name)!.isLate) {
          throw UnsupportedError(
              "Can't generate repository for $classType. The `$name` field MUST be final");
        }
        _checkIsFinal(element.supertype?.element, name);
      }
    }

    _checkIsFinal(classElement, 'id');

    for (final field in relationshipFields(classElement)) {
      _checkIsFinal(classElement, field.name);
    }

    // relationship-related

    final relationships = relationshipFields(classElement)
        .fold<Set<Map<String, String?>>>({}, (result, field) {
      final relationshipClassElement = field.typeElement;

      // define inverse

      final relationshipAnnotation = TypeChecker.fromRuntime(DataRelationship)
          .firstAnnotationOfExact(field, throwOnUnresolved: false);

      var inverse =
          relationshipAnnotation?.getField('inverse')?.toStringValue();

      if (inverse == null) {
        final possibleInverseElements =
            relationshipFields(relationshipClassElement).where((elem) {
          return (elem.type as ParameterizedType)
                  .typeArguments
                  .single
                  .element ==
              classElement;
        });

        if (possibleInverseElements.length > 1) {
          throw UnsupportedError('''
Too many possible inverses for relationship `${field.name}`
of type $classType: ${possibleInverseElements.map((e) => e.name).join(', ')}

Please specify the correct inverse in the $classType class, for example:

@DataRelationship(inverse: '${possibleInverseElements.first.name}')
final BelongsTo<${relationshipClassElement.name}> ${field.name};

and execute a code generation build again.
''');
        } else if (possibleInverseElements.length == 1) {
          inverse = possibleInverseElements.single.name;
        }
      }

      // prepare metadata

      final jsonKeyAnnotation = TypeChecker.fromRuntime(JsonKey)
          .firstAnnotationOfExact(field, throwOnUnresolved: false);

      final keyName = jsonKeyAnnotation?.getField('name')?.toStringValue();

      result.add({
        'key': keyName ?? field.name,
        'name': field.name,
        'inverse': inverse,
        'kind': field.type.element?.name,
        'type': DataHelpers.getType(relationshipClassElement.name),
      });

      return result;
    }).toList();

    final relationshipsFor = {
      for (final rel in relationships)
        '\'${rel['key']}\'': {
          '\'name\'': '\'${rel['name']}\'',
          if (rel['inverse'] != null) '\'inverse\'': '\'${rel['inverse']}\'',
          '\'type\'': '\'${rel['type']}\'',
          '\'kind\'': '\'${rel['kind']}\'',
          '\'instance\'': 'model?.' + rel['name']!,
        }
    };

    // serialization-related

    final hasFromJson =
        classElement.constructors.any((c) => c.name == 'fromJson');
    final fromJson = hasFromJson
        ? '$classType.fromJson(map)'
        : '_\$${classType}FromJson(map)';

    final methods = [
      ...classElement.methods,
      ...classElement.interfaces.map((i) => i.methods).expand((i) => i),
      ...classElement.mixins.map((i) => i.methods).expand((i) => i)
    ];
    final hasToJson = methods.any((c) => c.name == 'toJson');
    final toJson =
        hasToJson ? 'model.toJson()' : '_\$${classType}ToJson(model)';

    // additional adapters

    final remoteAdapterTypeChecker = TypeChecker.fromRuntime(RemoteAdapter);

    final mixins = annotation.read('adapters').listValue.map((obj) {
      final mixinType = obj.toTypeValue() as ParameterizedType;
      final mixinMethods = <MethodElement>[];
      String displayName;

      final args = mixinType.typeArguments;

      if (args.length > 1) {
        throw UnsupportedError(
            'Adapter `$mixinType` MUST have at most one type argument (T extends DataModel<T>) is supported for $mixinType');
      }

      if (!remoteAdapterTypeChecker.isAssignableFromType(mixinType)) {
        throw UnsupportedError(
            'Adapter `$mixinType` MUST have a constraint `on` RemoteAdapter<$classType>');
      }

      final instantiatedMixinType = (mixinType.element as ClassElement)
          .instantiate(
              typeArguments: [if (args.isNotEmpty) classElement.thisType],
              nullabilitySuffix: NullabilitySuffix.none);
      mixinMethods.addAll(instantiatedMixinType.methods);
      displayName =
          instantiatedMixinType.getDisplayString(withNullability: false);

      return displayName;
    }).toSet();

    final mixinShortcuts = mixins.map((mixin) {
      final mixinB = mixin.replaceAll(RegExp('\<.*?\>'), '').decapitalize();
      return '$mixin get $mixinB => remoteAdapter as $mixin;';
    }).join('\n');

    if (mixins.isEmpty) {
      mixins.add('NothingMixin');
    }

    final providerStringPlural = getProviderStringPlural(typeLowerCased);
    final providerStringSingular = getProviderStringSingular(typeLowerCased);

    // template

    return '''
// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member, non_constant_identifier_names

mixin \$${classType}LocalAdapter on LocalAdapter<$classType> {
  @override
  Map<String, Map<String, Object?>> relationshipsFor([$classType? model]) =>
    $relationshipsFor;

  @override
  $classType deserialize(map) {
    for (final key in relationshipsFor().keys) {
      map[key] = {
        '_': [map[key], !map.containsKey(key)],
      };
    }
    return $fromJson;
  }

  @override
  Map<String, dynamic> serialize(model) => $toJson;
}

// ignore: must_be_immutable
class \$${classType}HiveLocalAdapter = HiveLocalAdapter<$classType> with \$${classType}LocalAdapter;

class \$${classType}RemoteAdapter = RemoteAdapter<$classType> with ${mixins.join(', ')};

//

final ${typeLowerCased}RemoteAdapterProvider =
    Provider<RemoteAdapter<$classType>>(
        (ref) => \$${classType}RemoteAdapter(\$${classType}HiveLocalAdapter(ref.read), $providerStringSingular, $providerStringPlural));

final ${typeLowerCased}RepositoryProvider =
    Provider<Repository<$classType>>((ref) => Repository<$classType>(ref.read));

final _$providerStringSingular =
    StateNotifierProvider.autoDispose.family<DataStateNotifier<$classType?>, DataState<$classType?>, WatchArgs<$classType>>(
        (ref, args) {
  final adapter = ref.watch(${typeLowerCased}RemoteAdapterProvider);
  final notifier = adapter.strategies.watchersOne[args.watcher] ??
adapter.watchOneNotifier;
  return notifier(args.id!, remote: args.remote, params: args.params, headers: args.headers, alsoWatch: args.alsoWatch, finder: args.finder);
});

AutoDisposeStateNotifierProvider<DataStateNotifier<$classType?>, DataState<$classType?>> $providerStringSingular(Object? id,
    {bool? remote, Map<String, dynamic>? params, Map<String, String>? headers, AlsoWatch<$classType>? alsoWatch, String? finder, String? watcher}) {
  return _$providerStringSingular(WatchArgs(id: id, remote: remote, params: params, headers: headers, alsoWatch: alsoWatch, finder: finder, watcher: watcher));
}

final _$providerStringPlural =
    StateNotifierProvider.autoDispose.family<DataStateNotifier<List<$classType>>, DataState<List<$classType>>, WatchArgs<$classType>>(
        (ref, args) {
  final adapter = ref.watch(${typeLowerCased}RemoteAdapterProvider);
  final notifier = adapter.strategies.watchersAll[args.watcher] ??
adapter.watchAllNotifier;
  return notifier(remote: args.remote, params: args.params, headers: args.headers, syncLocal: args.syncLocal, finder: args.finder);
});

AutoDisposeStateNotifierProvider<DataStateNotifier<List<$classType>>, DataState<List<$classType>>> $providerStringPlural(
    {bool? remote, Map<String, dynamic>? params, Map<String, String>? headers, bool? syncLocal, String? finder, String? watcher}) {
  return _$providerStringPlural(WatchArgs(remote: remote, params: params, headers: headers, syncLocal: syncLocal, finder: finder, watcher: watcher));
}

extension ${classType}DataX on $classType {
  /// Initializes "fresh" models (i.e. manually instantiated) to use
  /// [save], [delete] and so on.
  /// 
  /// Can be obtained via `ref.read`, `container.read`
  $classType init(Reader read, {bool save = true}) {
    final repository = internalLocatorFn(${typeLowerCased}RepositoryProvider, read);
    final updatedModel = repository.remoteAdapter.initializeModel(this, save: save);
    return save ? updatedModel : this;
  }
}

extension ${classType}DataRepositoryX on Repository<$classType> {
$mixinShortcuts
}
''';
  }
}
