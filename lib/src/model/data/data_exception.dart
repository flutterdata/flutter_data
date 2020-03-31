part of flutter_data;

class DataException implements Exception {
  final Object errors;
  final int status;
  const DataException(this.errors, [this.status]);

  @override
  String toString() {
    return 'DataException: ${errors != null ? errors : ""} [HTTP $status]';
  }
}
