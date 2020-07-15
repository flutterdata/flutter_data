// ignore_for_file: prefer_interpolation_to_compose_strings

import 'dart:async';

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
    final typeInPlural = DataHelpers.getType(type);
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

    final mixins = annotation.read('adapters').listValue.map((obj) {
      var hasTypeArgument = false;
      final mixinType = obj.toTypeValue();
      if (mixinType is ParameterizedType) {
        final args = mixinType.typeArguments;
        assert(args.length > 1,
            'At most one type argument is supported for $mixinType');
        hasTypeArgument = args.length == 1;
      }

      for (final m in (mixinType.element as ClassElement)
          .methods
          .where((m) => m.isPublic)) {
        additionalMixinExtensionMethods[m.name] =
            '$m => (adapter as $mixinType).${m.name}(${m.parameters.map((p) => p.name).join(', ')});';
      }
      return '${mixinType.element.name}${hasTypeArgument ? "<$type>" : ""}';
    }).toSet();

    if (mixins.isEmpty) {
      mixins.add('NothingMixin');
    }

    // template

    return '''
// ignore_for_file: unused_local_variable, always_declare_return_types, non_constant_identifier_names, invalid_use_of_protected_member

mixin \$${type}LocalAdapter on LocalAdapter<$type> {
  @override
  Map<String, Map<String, Object>> relationshipsFor([$type model]) =>
    $relationshipsFor;

  @override
  deserialize(map) {
    for (final key in relationshipsFor().keys) {
      map[key] = {
        '_': [map[key], !map.containsKey(key)],
      };
    }
    return $fromJson;
  }

  @override
  serialize(model) {
    final map = $toJson;
    for (final e in relationshipsFor(model).entries) {
      map[e.key] = (e.value['instance'] as Relationship)?.toJson();
    }
    return map;
  }

}

// ignore: must_be_immutable
class \$${type}HiveLocalAdapter = HiveLocalAdapter<$type> with \$${type}LocalAdapter;

class \$${type}RemoteAdapter = RemoteAdapter<$type> with ${mixins.join(', ')};

//

final ${typeInPlural}LocalAdapterProvider = Provider<LocalAdapter<$type>>(
    (ref) => \$${type}HiveLocalAdapter(ref.read(graphProvider)));

final ${typeInPlural}RemoteAdapterProvider =
    Provider<RemoteAdapter<$type>>(
        (ref) => \$${type}RemoteAdapter(ref.read(${typeInPlural}LocalAdapterProvider)));

final ${typeInPlural}RepositoryProvider =
    Provider<Repository<$type>>((_) => Repository<$type>());


extension ${type}X on $type {
  $type init(owner) {
    return initFromRepository(
        owner.ref.read(${typeInPlural}RepositoryProvider) as Repository<$type>);
  }
}

extension ${type}RepositoryX on Repository<$type> {
  ${additionalMixinExtensionMethods.values.join('\n')}
}
''';
  }
}
