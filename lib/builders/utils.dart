import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:flutter_data/flutter_data.dart';
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:source_gen/source_gen.dart';

final relationshipTypeChecker = TypeChecker.fromRuntime(Relationship);
final dataModelTypeChecker = TypeChecker.fromRuntime(DataModelMixin);

extension ClassElementX on ClassElement {
  ConstructorElement? get freezedConstructor => constructors
      .where((c) => c.isFactory && c.displayName == name)
      // ignore: invalid_use_of_visible_for_testing_member
      .firstOrNull;

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

    return map.values.toList();
  }
}

extension VariableElementX on VariableElement {
  ClassElement get typeElement =>
      (type as ParameterizedType).typeArguments.single.element as ClassElement;
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
