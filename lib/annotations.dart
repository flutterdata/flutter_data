import 'package:meta/meta.dart';

class DataRepository {
  final List<Type> adapters;
  final List<Type> repositoryFor;
  const DataRepository(this.adapters, {this.repositoryFor = const []});
}

class DataRelationship {
  final String inverse;
  const DataRelationship({@required this.inverse});
}
