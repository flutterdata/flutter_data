// ignore_for_file: prefer_interpolation_to_compose_strings

import 'dart:async';

import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:build/build.dart';
import 'package:flutter_data/flutter_data.dart';
import 'package:source_gen/source_gen.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

import 'utils.dart';

Builder repositoryBuilder(options) =>
    SharedPartBuilder([RepositoryGenerator()], 'repository');

class RepositoryGenerator extends GeneratorForAnnotation<DataRepository> {
  @override
  Future<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) async {
    final type = element.name;
    final typeLowerCased = DataHelpers.getType(type).singularize();
    ClassElement classElement;

    // validations

    try {
      classElement = element as ClassElement;
    } catch (e) {
      throw UnsupportedError(
          "Can't generate repository for $type. Please use @DataRepository on a class.");
    }

    void _checkIsFinal(final ClassElement element, String name) {
      if (element != null) {
        if (element.getSetter(name) != null) {
          throw UnsupportedError(
              "Can't generate repository for $type. The `$name` field MUST be final");
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
        .fold<Set<Map<String, String>>>({}, (result, field) {
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
of type $type: ${possibleInverseElements.map((e) => e.name).join(', ')}

Please specify the correct inverse in the $type class, for example:

@DataRelationship(inverse: '${possibleInverseElements.first.name}')
final BelongsTo<${relationshipClassElement.name}> ${field.name};

and execute a code generation build again.
''');
        } else if (possibleInverseElements.length == 1) {
          inverse = possibleInverseElements.single.name;
        }
      }

      // prepare metadata

      result.add({
        'name': field.name,
        'inverse': inverse,
        'kind': field.type.element.name,
        'type': DataHelpers.getType(relationshipClassElement.name),
      });

      return result;
    }).toList();

    final relationshipsFor = {
      for (final rel in relationships)
        '\'${rel['name']}\'': {
          if (rel['inverse'] != null) '\'inverse\'': '\'${rel['inverse']}\'',
          '\'type\'': '\'${rel['type']}\'',
          '\'kind\'': '\'${rel['kind']}\'',
          '\'instance\'': 'model?.' + rel['name'],
        }
    };

    // serialization-related

    final hasFromJson =
        classElement.constructors.any((c) => c.name == 'fromJson');
    final fromJson =
        hasFromJson ? '$type.fromJson(map)' : '_\$${type}FromJson(map)';

    final methods = [
      ...classElement.methods,
      ...classElement.interfaces.map((i) => i.methods).expand((i) => i),
      ...classElement.mixins.map((i) => i.methods).expand((i) => i)
    ];
    final hasToJson = methods.any((c) => c.name == 'toJson');
    final toJson = hasToJson ? 'model.toJson()' : '_\$${type}ToJson(model)';

    // additional adapters

    final additionalMixinExtensionMethods = {};

    final remoteAdapterTypeChecker = TypeChecker.fromRuntime(RemoteAdapter);

    final mixins = annotation.read('adapters').listValue.map((obj) {
      final mixinType = obj.toTypeValue();
      final mixinMethods = <MethodElement>[];
      String displayName;
      var hasOnRemoteAdapter = false;

      if (mixinType is ParameterizedType) {
        final args = mixinType.typeArguments;

        if (args.length > 1) {
          throw UnsupportedError(
              'Adapter `$mixinType` MUST have at most one type argument (T extends DataModel<T>) is supported for $mixinType');
        }

        if (!remoteAdapterTypeChecker.isAssignableFromType(mixinType)) {
          throw UnsupportedError(
              'Adapter `$mixinType` MUST have a constraint `on` RemoteAdapter<$type>');
        }

        final instantiatedMixinType = (mixinType.element as ClassElement)
            .instantiate(
                typeArguments: [if (args.isNotEmpty) classElement.thisType],
                nullabilitySuffix: NullabilitySuffix.none);
        mixinMethods.addAll(instantiatedMixinType.methods);
        displayName = instantiatedMixinType.getDisplayString();

        hasOnRemoteAdapter = instantiatedMixinType.superclassConstraints
            .any((type) => remoteAdapterTypeChecker.isExactlyType(type));
      }

      for (final m in mixinMethods.where((m) => m.isPublic)) {
        // if method directly @overrides a method of RemoteAdapter, do not include
        if (!(m.hasOverride && hasOnRemoteAdapter)) {
          final params = m.parameters.map((p) {
            return p.isPositional ? p.name : '${p.name}: ${p.name}';
          }).join(', ');

          additionalMixinExtensionMethods[m.name] =
              '$m => (internalAdapter as $displayName).${m.name}($params);';
        }
      }

      return displayName;
    }).toSet();

    if (mixins.isEmpty) {
      mixins.add('NothingMixin');
    }

    final additionalMixinExtension = additionalMixinExtensionMethods.isNotEmpty
        ? '''
    extension ${type}RepositoryX on Repository<$type> {
      ${additionalMixinExtensionMethods.values.join('\n')}
    }'''
        : '';

    // imports

    // this library's imports (typically flutter_data, json_annotation, etc - NOT provider)
    // print((element.library?.imports ?? []).map((e) => '${e.declaration}'));

    final importProvider = await isDependency('provider', buildStep);
    final importGetIt = await isDependency('get_it', buildStep);
    final importFlutterRiverpod =
        await isDependency('flutter_riverpod', buildStep) ||
            await isDependency('hooks_riverpod', buildStep);

    final initArg =
        (importProvider || importFlutterRiverpod) ? 'context' : 'owner';
    final initArgOptional = importGetIt ? '[$initArg]' : initArg;

    // template

    return '''
// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

mixin \$${type}LocalAdapter on LocalAdapter<$type> {
  @override
  Map<String, Map<String, Object>> relationshipsFor([$type model]) =>
    $relationshipsFor;

  @override
  $type deserialize(map) {
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
class \$${type}HiveLocalAdapter = HiveLocalAdapter<$type> with \$${type}LocalAdapter;

class \$${type}RemoteAdapter = RemoteAdapter<$type> with ${mixins.join(', ')};

//

final ${typeLowerCased}LocalAdapterProvider = Provider<LocalAdapter<$type>>(
    (ref) => \$${type}HiveLocalAdapter(ref.read(hiveLocalStorageProvider), ref.read(graphProvider)));

final ${typeLowerCased}RemoteAdapterProvider =
    Provider<RemoteAdapter<$type>>(
        (ref) => \$${type}RemoteAdapter(ref.read(${typeLowerCased}LocalAdapterProvider)));

final ${typeLowerCased}RepositoryProvider =
    Provider<Repository<$type>>((_) => Repository<$type>());


extension ${type}X on $type {
  $type init($initArgOptional) {
    return internalLocatorFn(${typeLowerCased}RepositoryProvider, $initArg).internalAdapter.initializeModel(this, save: true) as $type;
  }
}

$additionalMixinExtension

''';
  }
}
