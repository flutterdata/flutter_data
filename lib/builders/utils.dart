import 'package:build/build.dart';
import 'package:flutter_data/flutter_data.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:source_gen/source_gen.dart';

final relationshipTypeChecker = TypeChecker.fromRuntime(Relationship);
final dataModelTypeChecker = TypeChecker.fromRuntime(DataModel);

// unique collection of constructor arguments and fields
Iterable<VariableElement> relationshipFields(ClassElement elem) {
  Map<String, VariableElement> map;

  map = {
    for (final field in elem.fields)
      if (relationshipTypeChecker.isSuperOf(field.type.element))
        field.name: field,
  };

  // if no relationships were found, we might be in presence
  // of a Freezed object, so check factory constructors
  if (map.isEmpty) {
    map = {
      for (final constructor in elem.constructors)
        if (constructor.isFactory)
          for (final param in constructor.parameters)
            if (relationshipTypeChecker.isSuperOf(param.type.element))
              param.name: param,
    };
  }

  final out = map.values.toList();

  // if parent mixes DataModel in, also include its relationships
  if (elem.supertype != null &&
      dataModelTypeChecker.isAssignableFrom(elem.supertype.element)) {
    out.addAll(relationshipFields(elem.supertype.element));
  }

  return out;
}

extension VariableElementX on VariableElement {
  ClassElement get typeElement =>
      (type as ParameterizedType).typeArguments.single.element as ClassElement;
}

Pubspec _pubspec;

Future<bool> isDependency(String package, BuildStep buildStep) async {
  _pubspec ??= Pubspec.parse(await buildStep
      .readAsString(AssetId(buildStep.inputId.package, 'pubspec.yaml')));
  return _pubspec.dependencies.keys.any((key) => key == package);
}
