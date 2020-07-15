import 'package:flutter_data/flutter_data.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:source_gen/source_gen.dart';

final relationshipTypeChecker = TypeChecker.fromRuntime(Relationship);

// unique collection of constructor arguments and fields
Iterable<VariableElement> relationshipFields(ClassElement elem) {
  return <String, VariableElement>{
    for (final field in elem.fields)
      if (relationshipTypeChecker.isSuperOf(field.type.element))
        field.name: field,
    // for (final constructor in elem.constructors)
    //   for (final param in constructor.parameters)
    //     if (relationshipTypeChecker.isSuperOf(param.type.element))
    //       param.name: param,
  }.values;
}

extension VBX on VariableElement {
  ClassElement get typeElement =>
      (type as ParameterizedType).typeArguments.single.element as ClassElement;
}
