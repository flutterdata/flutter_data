import 'package:flutter_data/flutter_data.dart';
import 'package:test/test.dart';

import '../_support/familia.dart';
import '../_support/node.dart';
import '../_support/person.dart';
import '../_support/pet.dart';
import '../_support/setup.dart';

void main() async {
  setUp(setUpFn);
  tearDown(tearDownFn);

  test('init', () async {
    final familia = Familia(id: '55', surname: 'Kelley');
    expect(await container.familia.findOne('55', remote: false), isNotNull);

    final person =
        Person(id: '1', name: 'John', age: 27, familia: familia.asBelongsTo);
    await person.save();

    // redundantly init'ing has no effect
    person.init();

    // (1) it wires up the relationship
    expect(person.familia.key, graph.getKeyForId('familia', '55'));

    // (2) it saves the model locally
    expect(person, await container.people.findOne(person.id!, remote: false));
  });

  test('was', () {
    final p = Person(id: '1', name: 'Peter');
    final p2 = Person(id: '2', name: 'Petera');
    // keys are different
    expect(keyFor(p), isNot(keyFor(p2)));

    p2.was(p);

    // now both objects have the same key
    expect(keyFor(p), keyFor(p2));

    // now the original key is associated to id=2
    expect(graph.getKeyForId('people', '1'), isNull);
    expect(graph.getKeyForId('people', '2'), keyFor(p));

    //

    final p3 = Person(name: 'Robert');
    final p4 = Person(name: 'Roberta');

    expect(keyFor(p3), isNot(keyFor(p4)));

    p4.was(p3);
    expect(keyFor(p3), keyFor(p4));

    //

    final p5 = Person(name: 'Thiago');
    final p6 = Person(id: '7', name: 'Thiaga');

    expect(keyFor(p5), isNot(keyFor(p6)));

    p6.was(p5);
    expect(keyFor(p5), keyFor(p6));

    // now the original key is associated to id=7
    expect(graph.getKeyForId('people', '7'), keyFor(p5));

    //

    final p7 = Person(id: '8', name: 'Evo');
    final p8 = Person(name: 'Eva');

    expect(keyFor(p7), isNot(keyFor(p8)));

    p8.was(p7);
    expect(keyFor(p7), keyFor(p8));

    // now no key is associated to id=8
    expect(graph.getKeyForId('people', '8'), keyFor(p7));
  });

  test('manual init', () {
    // Node has autoInitialization set to false
    // if child node is not initialized, it can't be passed to a relationship
    expect(
        () => Node(name: 'parent', children: {Node(name: 'child')}.asHasMany),
        throwsA(isA<AssertionError>()));

    // now that it is, ensure keys and toString work properly
    final node =
        Node(name: 'parent', children: {Node(name: 'child').init()}.asHasMany);
    expect(node.children!.keys, isEmpty);

    // since testing on web is a complete pain in the ass, skip this last part
    const kIsWeb = identical(0, 0.0);
    if (kIsWeb) return;

    expect(node.toString(),
        'Node(id: null, name: parent, parent: null, children: HasMany<Node>())');

    final n = Node(name: 'parent');
    // can't get key because `n` was not initialized
    expect(() => n.copyWith(name: 'parent2').was(n),
        throwsA(isA<AssertionError>()));

    final n2 = n.init();
    n2.copyWith(name: 'parent2').was(n2);
  });

  test('findOne (remote reload)', () async {
    var familia = await Familia(id: '1', surname: 'Perez').save(remote: true);
    familia = Familia(id: '1', surname: 'Perez Gomez');

    container.read(responseProvider.notifier).state = TestResponse.text('''
        { "id": "1", "surname": "Perez" }
      ''');

    familia = (await familia.reload())!;
    expect(familia, Familia(id: '1', surname: 'Perez'));
    expect(await container.familia.findOne('1'),
        Familia(id: '1', surname: 'Perez'));
  });

  test('delete model with and without ID', () async {
    final adapter = container.people.remoteAdapter.localAdapter;
    // create a person WITH ID and assert it's there
    final person = Person(id: '21103', name: 'John', age: 54);
    expect(adapter.findAll(), hasLength(1));

    // delete that person and assert it's not there
    await person.delete();
    expect(adapter.findAll(), hasLength(0));

    // create a person WITHOUT ID and assert it's there
    final person2 = Person(name: 'Peter', age: 101);
    expect(adapter.findAll(), hasLength(1));

    // delete that person and assert it's not there
    await person2.delete();
    expect(adapter.findAll(), hasLength(0));
  });

  test('should reuse key', () {
    // id-less person
    final p1 = Person(name: 'Frank', age: 20);
    expect(
        (container.people.remoteAdapter.localAdapter
                as HiveLocalAdapter<Person>)
            .box!
            .keys,
        contains(keyFor(p1)));

    // person with new id, reusing existing key
    graph.getKeyForId('people', '221', keyIfAbsent: keyFor(p1));
    final p2 = Person(id: '221', name: 'Frank2', age: 32);
    expect(keyFor(p1), keyFor(p2));

    expect(
        (container.people.remoteAdapter.localAdapter
                as HiveLocalAdapter<Person>)
            .box!
            .keys,
        contains(keyFor(p2)));
  });

  test('equality', () async {
    /// Charles was once called Walter
    final p1a = Person(id: '2', name: 'Walter', age: 20);
    final p1b = Person(id: '2', name: 'Charles', age: 21);
    // they maintain same key as they're the same person
    expect(keyFor(p1a), keyFor(p1b));
    expect(p1a, isNot(p1b));
  });

  test('should work with subclasses', () {
    final dog = Dog(id: '2', name: 'Walker');
    final f = Familia(surname: 'Walker', dogs: {dog}.asHasMany);
    expect(f.dogs!.first.name, 'Walker');
  });

  test('data exception equality', () {
    final exception = Exception('whatever');
    expect(DataException(exception, statusCode: 410),
        DataException(exception, statusCode: 410));
    expect(DataException([exception], statusCode: 410),
        isNot(DataException(exception, statusCode: 410)));
  });
}
