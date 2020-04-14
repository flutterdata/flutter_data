part of flutter_data;

class DataException implements Exception {
  final Object errors;
  final int status;
  const DataException([this.errors = const [], this.status]);

  @override
  bool operator ==(dynamic other) =>
      identical(this, other) || toString() == other.toString();

  @override
  int get hashCode => runtimeType.hashCode ^ status.hashCode ^ errors.hashCode;

  @override
  String toString() {
    return 'DataException: [HTTP $status] $errors';
  }
}
