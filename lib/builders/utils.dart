import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:flutter_data/flutter_data.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:source_gen/source_gen.dart';
import 'package:source_helper/source_helper.dart';

final relationshipTypeChecker = TypeChecker.fromRuntime(Relationship);
final dataModelTypeChecker = TypeChecker.fromRuntime(DataModel);

extension ClassElementX on ClassElement {
  DartObject? get fieldRename {
    final annot = TypeChecker.fromRuntime(JsonSerializable);

    var fieldRename = annot
        .firstAnnotationOfExact(this, throwOnUnresolved: false)
        ?.getField('fieldRename');
    if (fieldRename == null && freezedConstructor != null) {
      fieldRename = annot
          .firstAnnotationOfExact(freezedConstructor!, throwOnUnresolved: false)
          ?.getField('fieldRename');
    }
    return fieldRename;
  }

  ConstructorElement? get freezedConstructor => constructors
      .where((c) => c.isFactory && c.displayName == name)
      // ignore: invalid_use_of_visible_for_testing_member
      .safeFirst;

  // unique collection of constructor arguments and fields
  Iterable<VariableElement> get relationshipFields {
    Map<String, VariableElement> map;

    map = {
      for (final field in fields)
        if (field.type.element is ClassElement &&
            field.isPublic &&
            (field.type.element as ClassElement).supertype != null &&
            relationshipTypeChecker.isSuperOf(field.type.element!))
          field.name: field,
      // also check freezed
      if (freezedConstructor != null)
        for (final param in freezedConstructor!.parameters)
          if (param.type.element != null &&
              relationshipTypeChecker.isSuperOf(param.type.element!))
            param.name: param,
    };

    return map.values.toList()..sort((a, b) => a.name.compareTo(b.name));
  }

  // unique collection of constructor arguments and fields
  Iterable<VariableElement> get attributeFields {
    Map<String, VariableElement> map;

    map = {
      for (final field in fields)
        if (field.type.element is ClassElement &&
            field.isPublic &&
            ((field.type.element as ClassElement).supertype != null) &&
            !relationshipTypeChecker.isSuperOf(field.type.element!) &&
            !['id', 'hashCode', '=='].contains(field.name))
          field.name: field,
      // also check freezed
      if (freezedConstructor != null)
        for (final param in freezedConstructor!.parameters)
          if (param.type.element != null &&
              !relationshipTypeChecker.isSuperOf(param.type.element!) &&
              !['id', 'hashCode', '=='].contains(param.name))
            param.name: param,
    };

    return map.values.toList()..sort((a, b) => a.name.compareTo(b.name));
  }
}

extension VariableElementX on VariableElement {
  ClassElement get typeElement =>
      (type as ParameterizedType).typeArguments.single.element as ClassElement;

  List<String> get internalType {
    // TODO disable:
    // - final double float;
    // - final List listDynamic;
    // - final num number;
    // - assert all iterables are of type string

    final jsonKeyAnnotation = TypeChecker.fromRuntime(JsonKey)
        .firstAnnotationOfExact(this, throwOnUnresolved: false);
    final toJsonFn = jsonKeyAnnotation?.getField('toJson')?.toFunctionValue();

    // ignore: no_leading_underscores_for_local_identifiers
    var _internalType = type.element!.name!;

    var typeArgs = (type as ParameterizedType).typeArguments.toList();
    if (typeArgs.join() == 'dynamic') typeArgs = [];

    String _addTypeArgs(String value) =>
        '$value${typeArgs.isNotEmpty ? '<${typeArgs.map((t) => t.getDisplayString(withNullability: false)).join(', ')}>' : ''}';

    if (toJsonFn?.returnType.element?.name != null) {
      _internalType = toJsonFn!.returnType.element!.name!;
    } else if (['DateTime', 'Uri', 'BigInt'].contains(_internalType)) {
      _internalType = 'String';
    } else if (type.isEnum || _internalType.startsWith('Duration')) {
      _internalType = 'int';
    } else if (_internalType.startsWith('num')) {
      _internalType = 'double';
    } else if (['Iterable', 'List', 'Set'].contains(_internalType)) {
      // ignore: invalid_use_of_visible_for_testing_member
      final firstType = typeArgs.safeFirst?.toString();
      if (firstType != null &&
          (firstType.startsWith('int') || firstType.startsWith('bool'))) {
        _internalType = _addTypeArgs('List');
      } else {
        _internalType = 'List';
      }
    } else if (_internalType == 'Map') {
      // ignore: invalid_use_of_visible_for_testing_member
      if (typeArgs.safeFirst.toString() != 'String') {
        throw UnsupportedError(
            'The ${_addTypeArgs('Map')} type of field $name is not supported. Only String keys are.');
      }
    }
    return [
      _addTypeArgs(type.element!.name!),
      (type.isEnum ||
              // ignore: invalid_use_of_visible_for_testing_member
              (typeArgs.safeFirst?.isNullableType ?? type.isNullableType))
          .toString(),
      _internalType,
    ];
  }

  String finalNameFor(ClassElement classElement) {
    final jsonKeyAnnotation = TypeChecker.fromRuntime(JsonKey)
        .firstAnnotationOfExact(this, throwOnUnresolved: false);

    // try to guess correct key name in json_serializable
    var keyName = jsonKeyAnnotation?.getField('name')?.toStringValue();

    if (keyName == null && classElement.fieldRename != null) {
      final fieldCase =
          classElement.fieldRename!.getField('_name')?.toStringValue();
      switch (fieldCase) {
        case 'kebab':
          keyName = name.kebab;
          break;
        case 'snake':
          keyName = name.snake;
          break;
        case 'pascal':
          keyName = name.pascal;
          break;
        case 'none':
          keyName = name;
          break;
        default:
      }
    }

    return keyName ??= name;
  }
}

Future<bool> isDependency(String package, BuildStep buildStep,
    {bool dev = false}) async {
  final pubspec = Pubspec.parse(await buildStep
      .readAsString(AssetId(buildStep.inputId.package, 'pubspec.yaml')));
  var deps = pubspec.dependencies;
  if (dev) {
    deps = pubspec.devDependencies;
  }
  return deps.keys.any((key) => key == package);
}

String getProviderStringPlural(String type) => '${type}Provider';
String getProviderStringSingular(String type) =>
    '${type.singularize()}${(type.singularize() == type.pluralize() ? 'One' : '')}Provider';
