class DataRepository {
  final List<Type> adapters;
  final List<Type> repositoryFor;
  const DataRepository(this.adapters, {this.repositoryFor = const []});
}
