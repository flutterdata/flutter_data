import 'dart:convert';

import 'package:flutter_data/flutter_data.dart';
import 'package:test/test.dart';

import '../_support/book.dart';
import '../_support/familia.dart';
import '../_support/house.dart';
import '../_support/person.dart';
import '../_support/setup.dart';

void main() async {
  setUp(setUpFn);
  tearDown(tearDownFn);

  test('findAll', () async {
    final adapter = container.familia.remoteAdapter;
    final familia1 = Familia(id: '1', surname: 'Smith');
    final familia2 = Familia(id: '2', surname: 'Jones');

    await adapter.save(familia1);
    await adapter.save(familia2);
    final familia = await adapter.findAll(remote: false);

    expect(familia, [familia1, familia2]);
  });

  test('findOne', () async {
    final adapter = container.familia.remoteAdapter;
    final familia1 = Familia(id: '1', surname: 'Smith');
    await adapter.save(familia1, remote: false);

    final familia = await adapter.findOne('1', remote: false);
    expect(familia, familia1);
  });

  test('findOne with non-existing ID', () async {
    final adapter = container.familia.remoteAdapter;
    final model = await adapter.findOne('123', remote: false);
    expect(model, isNull);
  });

  test('findOne with includes', () async {
    final data =
        await container.familia.remoteAdapter.deserialize(json.decode('''
      { "id": "1", "surname": "Smith", "persons": [{"_id": "1", "name": "Stan", "age": 31}] }
    ''') as Object);
    expect(data.model, Familia(id: '1', surname: 'Smith'));
    expect(data.included, [Person(id: '1', name: 'Stan', age: 31)]);
  });

  test('create and save', () async {
    final house = House(id: '25', address: '12 Lincoln Rd');
    // repo.findOne works because the House repo is remote=false
    expect(await container.houses.remoteAdapter.findOne(house.id!), house);
  });

  test('save and find', () async {
    final adapter = container.familia.remoteAdapter;
    final familia = Familia(id: '32423', surname: 'Toraine');
    await adapter.save(familia);

    final familia2 = await adapter.findOne('32423', remote: false);
    expect(familia, familia2);
  });

  test('delete', () async {
    final adapter = container.people.remoteAdapter;
    // init a person
    final person = Person(id: '1', name: 'John', age: 21);
    // it does have a key
    expect(graph.getKeyForId('people', person.id), isNotNull);

    // now delete
    await adapter.delete(person.id!);

    // so fetching by id again is null
    expect(await adapter.findOne(person.id!), isNull);

    // and now key & id are both non-existent
    expect(graph.getNode(keyFor(person)!), isNull);
    expect(graph.getKeyForId('people', person.id), isNull);
  });

  test('use default headers & params', () async {
    final adapter = container.people.personLoginAdapter;

    container.read(responseProvider.notifier).state =
        TestResponse.text('{"message": "hello"}');
    expect(await adapter.hello(), 'hello');

    container.read(responseProvider.notifier).state =
        TestResponse(text: (req) => req.headers['response']!);
    expect(await adapter.hello(useDefaultHeaders: true),
        'not the message you sent');

    container.read(responseProvider.notifier).state =
        TestResponse(text: (req) => '{"url" : "${req.url.toString()}"}');
    expect(await adapter.url({'a': 1}),
        'https://override-base-url-in-adapter/url?a=1');
    expect(await adapter.url({'b': 2}, useDefaultParams: true),
        'https://override-base-url-in-adapter/url?b=2&default=true');
  });

  test('can override type', () {
    final author = BookAuthor(id: 15, name: 'Walter', books: HasMany());
    final adapter = adapterFor(author)!;
    expect(adapter.type, 'writers');
    expect(adapter.internalType, 'bookAuthors');

    // check key was correctly assigned
    // ignore: invalid_use_of_protected_member
    final key = adapter.graph.getKeyForId(adapter.internalType, 15);
    expect(keyFor(author), equals(key));
  });

  test('issue 148', () async {
    container.read(responseProvider.notifier).state = TestResponse.text('''[
          {"id": "1", "surname": "Smith", "persons": [
              {
                "_id": "1",
                "name": "Peter",
                "age": 10
              },
              {
                "_id": "2",
                "name": "John",
                "age": 44
              }
            ]
          }
        ]''');

    // remote comes back with relationships
    final models = await container.familia.findAll(remote: true);
    expect(models!.first.persons.toList(), [
      Person(id: '1', name: 'Peter', age: 10),
      Person(id: '2', name: 'John', age: 44)
    ]);

    final originalKey = keyFor(models.first)!;

    // simulate app restart
    container.familia.dispose();
    await container.read(familiaRepositoryProvider).initialize(
          // ignore: invalid_use_of_protected_member
          adapters: container.familia.remoteAdapter.adapters,
        );
    await container.familia.remoteAdapter.localAdapter
        .save(originalKey, Familia(id: '1', surname: 'Smith'), notify: false);

    // local storage still comes back with relationships
    final models2 = await container.familia.findAll(remote: false);
    expect(models2!.first.persons.toList(), [
      Person(id: '1', name: 'Peter', age: 10),
      Person(id: '2', name: 'John', age: 44)
    ]);
  });

  test('DataRequestLabel', () {
    final label = DataRequestLabel('findAll', type: 'dogs');
    expect(label.kind, 'findAll');
    expect(label.type, 'dogs');
    expect(label.requestId, isNotNull);

    final label2 = DataRequestLabel.parse('findOne/watch/dogs#1@7ebcc6');
    expect(label2.kind, 'findOne/watch');
    expect(label2.type, 'dogs');
    expect(label2.id, '1');
    expect(label2.requestId, '7ebcc6');
    expect(label2.indentation, 0);

    // indentation does not depend on left padding
    final label3 = DataRequestLabel.parse('   findAll/dogs@4ebcc6');
    expect(label3.kind, 'findAll');
    expect(label3.type, 'dogs');
    expect(label3.id, isNull);
    expect(label3.requestId, '4ebcc6');
    expect(label3.indentation, 0);

    // nested
    final parentLabel =
        DataRequestLabel('findOne', id: '1', type: 'dogs', requestId: 'ee58b2');
    final nestedLabel1 = DataRequestLabel('findAll',
        type: 'parks', requestId: 'ff01b1', withParent: parentLabel);
    final nestedLabel2 = DataRequestLabel('findAll',
        type: 'rangers', requestId: 'e7bf99', withParent: nestedLabel1);

    expect(parentLabel.toString(), 'findOne/dogs#1@ee58b2');
    expect(parentLabel.requestId, 'ee58b2');
    expect(parentLabel.indentation, 0);

    expect(nestedLabel1.toString(), 'findAll/parks@ff01b1<ee58b2');
    expect(nestedLabel1.requestId, 'ff01b1');
    expect(nestedLabel1.indentation, 1);

    expect(nestedLabel2.toString(), 'findAll/rangers@e7bf99<ff01b1<ee58b2');
    expect(nestedLabel2.requestId, 'e7bf99');
    expect(nestedLabel2.indentation, 2);
  });

  test('keyForModelOrId', () {
    final adapter = container.people.remoteAdapter;
    final p1 = Person(name: 'Ludwig');
    final key1 = adapter.keyForModelOrId(p1);
    expect(key1, keyFor(p1)!);

    final key2 = graph.getKeyForId('people', '43',
        keyIfAbsent: DataHelpers.generateKey<Person>());
    final key2b = adapter.keyForModelOrId('43');
    expect(key2, key2b);

    final p3 = Person(id: '22', name: 'Joe');
    final key3 = adapter.keyForModelOrId(p3);
    final key3b = graph.getKeyForId('people', '22');
    expect(key3, key3b);
  });
}
