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
    final familia1 = Familia(id: '1', surname: 'Smith');
    final familia2 = Familia(id: '2', surname: 'Jones');

    await familiaRemoteAdapter.save(familia1);
    await familiaRemoteAdapter.save(familia2);
    final familia = await familiaRemoteAdapter.findAll(remote: false);

    expect(familia, [familia1, familia2]);
  });

  test('findOne', () async {
    final familia1 = Familia(id: '1', surname: 'Smith');

    await familiaRemoteAdapter.save(familia1); // possible to save without init
    final familia = await familiaRemoteAdapter.findOne('1', remote: false);
    expect(familia, familia1);
  });

  test('findOne with includes', () async {
    final data = familiaRemoteAdapter.deserialize(json.decode('''
      { "id": "1", "surname": "Smith", "persons": [{"_id": "1", "name": "Stan", "age": 31}] }
    ''') as Object);
    expect(data.model, Familia(id: '1', surname: 'Smith'));
    expect(data.included, [Person(id: '1', name: 'Stan', age: 31)]);
  });

  test('create and save', () async {
    final house = House(id: '25', address: '12 Lincoln Rd');

    // the house is not initialized, so we shouldn't be able to find it
    expect(await houseRemoteAdapter.findOne(house.id!), isNull);

    // now initialize
    house.init(container.read);

    // repo.findOne works because the House repo is remote=false
    expect(await houseRemoteAdapter.findOne(house.id!), house);
  });

  test('save and find', () async {
    final familia = Familia(id: '32423', surname: 'Toraine');
    await familiaRemoteAdapter.save(familia);

    final familia2 = await familiaRemoteAdapter.findOne('32423', remote: false);
    expect(familia, familia2);
  });

  test('delete', () async {
    // init a person
    final person = Person(id: '1', name: 'John', age: 21).init(container.read);
    // it does have a key
    expect(graph.getKeyForId('people', person.id), isNotNull);

    // now delete
    await personRemoteAdapter.delete(person.id!);

    // so fetching by id again is null
    expect(await personRemoteAdapter.findOne(person.id!), isNull);

    // and now key & id are both non-existent
    expect(graph.getNode(keyFor(person)!), isNull);
    expect(graph.getKeyForId('people', person.id), isNull);
  });

  test('use default headers & params', () async {
    final adapter = personRemoteAdapter as PersonLoginAdapter;

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
    final author = BookAuthor(id: 15, name: 'Walter').init(container.read);
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
    final models = await familiaRepository.findAll(remote: true);
    expect(models.first.persons.toList(), [
      Person(id: '1', name: 'Peter', age: 10),
      Person(id: '2', name: 'John', age: 44)
    ]);

    final originalKey = keyFor(models.first)!;

    // simulate app restart
    familiaRepository.dispose();
    familiaRepository =
        await container.read(familiaRepositoryProvider).initialize(
              // ignore: invalid_use_of_protected_member
              adapters: familiaRemoteAdapter.adapters,
            );
    await familiaRemoteAdapter.localAdapter
        .save(originalKey, Familia(id: '1', surname: 'Smith'), notify: false);

    // local storage still comes back with relationships
    final models2 = await familiaRepository.findAll(remote: false);
    expect(models2.first.persons.toList(), [
      Person(id: '1', name: 'Peter', age: 10),
      Person(id: '2', name: 'John', age: 44)
    ]);
  });

  // TODO test with background=true
}
