part of flutter_data;

// Poor man's Provider
@optionalTypeArgs
class DataServiceLocator<E> {
  Locator get locator => <E>() => _registry[E] as E;

  // registry & locator

  final _registry = <Type, E>{};

  void register<R extends E>(R obj) {
    _registry[R] = obj;
  }

  void clear() => _registry.clear();
}
