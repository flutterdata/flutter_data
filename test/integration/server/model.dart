class Company {
  final String id;
  String headquarters;
  final models = <String>{};

  /// Company name
  String name;

  /// NASDAQ symbol
  String nasdaq;

  DateTime updatedAt = DateTime.now();

  Company(this.id);
}

class City {
  final String id;
  String name;

  City(this.id);
}

class Model {
  final String id;
  String name;

  Model(this.id);
}
