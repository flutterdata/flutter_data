part of flutter_data;

typedef Locator = T Function<T>();

// Poor man's Provider
@optionalTypeArgs
class DataServiceLocator<E> {
  Locator get locator => <E>() {
        // FIXME go figure WTF _registry[E] randomly returns null
        return _registry['$E'] as E;
      };

  // registry & locator

  final _registry = <String, E>{};

  void register<R extends E>(R obj) {
    _registry['$R'] = obj;
  }

  void clear() => _registry.clear();
}
