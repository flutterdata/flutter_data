import 'dart:typed_data';

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
    final adapter = container.familia;
    final familia1 = Familia(id: '1', surname: 'Smith');
    final familia2 = Familia(id: '2', surname: 'Jones');

    await adapter.save(familia1);
    await adapter.save(familia2);
    final familia = await adapter.findAll(remote: false);

    expect(familia, unorderedEquals([familia1, familia2]));
  });

  test('findOne', () async {
    final adapter = container.familia;
    final familia1 = Familia(id: '1', surname: 'Smith');
    await adapter.save(familia1, remote: false);

    final familia = await adapter.findOne('1', remote: false);
    expect(familia, familia1);
  });

  test('findOne with non-existing ID', () async {
    final adapter = container.familia;
    final model = await adapter.findOne('123', remote: false);
    expect(model, isNull);
  });

  test('create and save', () async {
    final house = House(id: '25', address: '12 Lincoln Rd').saveLocal();
    expect(container.houses.findOneLocalById(house.id!), house);
  });

  test('save and find', () async {
    final adapter = container.familia;
    final familia = Familia(id: '32423', surname: 'Toraine');
    await adapter.save(familia);

    final familia2 = await adapter.findOne('32423', remote: false);
    expect(familia, familia2);
  });

  test('delete', () async {
    final adapter = container.people;

    final person = Person(id: '1', name: 'John', age: 21);
    // it does have a key
    expect(core.getKeyForId('people', person.id), isNotNull);

    // now delete
    await adapter.delete(person.id!);

    // so fetching by id again is null
    expect(adapter.findOneLocalById(person.id!), isNull);

    // and now key is no longer stored
    expect(core.getIdForKey(keyFor(person)), isNull);
  });

  test('use default headers & params', () async {
    final adapter = container.people.personLoginAdapter;

    container.read(responseProvider.notifier).state =
        TestResponse.json('{"message": "hello"}');
    expect(await adapter.hello(), 'hello');

    container.read(responseProvider.notifier).state = TestResponse(
      (_) async => '{"message": "hello"}',
      headers: {
        'X-Url': 'http://example.com',
        'content-type': 'application/json'
      },
    );
    expect(await adapter.example(), 'http://example.com');

    container.read(responseProvider.notifier).state = TestResponse(
      (req) async => req.headers['response']!,
    );
    expect(await adapter.hello(useDefaultHeaders: true),
        'not the message you sent');

    container.read(responseProvider.notifier).state = TestResponse(
      (req) async => '{"url" : "${req.url.toString()}"}',
    );

    // also tests overridden `urlForFindOne` in Person
    expect(await adapter.url({'a': 1}),
        'https://override-base-url-in-adapter/endpoint?url=url&a=1');
    expect(await adapter.url({'b': 2}, useDefaultParams: true),
        'https://override-base-url-in-adapter/endpoint?url=url&b=2&default=true');
  });

  test('can override type', () {
    final author = BookAuthor(id: 15, name: 'Walter', books: HasMany());
    final adapter = DataModel.adapterFor(author);
    expect(adapter.type, 'writers');
    expect(adapter.internalType, 'bookAuthors');

    // check key was correctly assigned
    // ignore: invalid_use_of_protected_member
    final key = adapter.core.getKeyForId(adapter.internalType, 15);
    expect(keyFor(author), equals(key));
  });

  test('issue 148', () async {
    container.read(responseProvider.notifier).state = TestResponse.json('''[
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
    final models = await container.familia.findAll();
    expect(
        models.first.persons.toSet(),
        unorderedEquals({
          Person(id: '1', name: 'Peter', age: 10),
          Person(id: '2', name: 'John', age: 44)
        }));

    // simulate app restart
    container.familia.dispose();

    await container
        .read(familiaAdapterProvider)
        .initialize(ref: container.read(refProvider));

    container.familia
        .saveLocal(Familia(id: '1', surname: 'Smith'), notify: false);

    // local storage still comes back with relationships
    final models2 = container.familia.findAllLocal();
    expect(
        models2.first.persons.toList(),
        unorderedEquals([
          Person(id: '1', name: 'Peter', age: 10),
          Person(id: '2', name: 'John', age: 44)
        ]));
  });

  test('DataRequestLabel', () {
    final label = DataRequestLabel('findAll', type: 'dogs');
    expect(label.kind, 'findAll');
    expect(label.type, 'dogs');
    expect(label.requestId, isNotNull);

    final label2 = DataRequestLabel.parse('findOne/watch/dogs#1@7ebcc6');
    expect(label2.kind, 'findOne/watch');
    expect(label2.type, 'dogs');
    expect(label2.id, 1);
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
        DataRequestLabel('findOne', id: 1, type: 'dogs', requestId: 'ee58b2');
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
    final adapter = container.people;
    final p1 = Person(name: 'Ludwig');
    final key1 = core.getKeyForModelOrId(adapter.type, p1);
    expect(key1, keyFor(p1));

    final key2 = core.getKeyForId('people', '43');
    final key2b = core.getKeyForModelOrId(adapter.type, '43');
    expect(key2, key2b);

    final p3 = Person(id: '22', name: 'Joe');
    final key3 = core.getKeyForModelOrId(adapter.type, p3);
    final key3b = core.getKeyForId('people', '22');
    expect(key3, key3b);
  });

  test('304 not modified', () async {
    final adapter = container.people;

    Person(id: '2', name: 'Julian').saveLocal();

    container.read(responseProvider.notifier).state = TestResponse(
      (_) async {
        return '';
      },
      statusCode: 304,
    );

    expect(await adapter.findOne('2'),
        isA<Person>().having((p) => p.name, 'name', 'Julian'));

    expect(await adapter.findAll(),
        isA<List<Person>>().having((p) => p.first.name, 'name', 'Julian'));
  });

  test('plain text', () async {
    container.read(responseProvider.notifier).state = TestResponse(
        (_) async => 'plain text',
        headers: {'content-type': 'text/plain'});

    final text = await container.familia.sendRequest('/plain'.asUri);
    expect(text, 'plain text');
  });

  test('body bytes', () async {
    container.read(responseProvider.notifier).state =
        TestResponse((_) async => 'some text');

    final response = await container.familia.sendRequest<Uint8List>(
      ''.asUri,
      returnBytes: true,
      onSuccess: (response, label) async {
        expect(response.body, 'some text'.codeUnits);
        return response.body as Uint8List;
      },
    );
    expect(response, 'some text'.codeUnits);
  });

  test('issue 218', () async {
    // start with a family with no ID + a person with no ID
    final f1 = Familia(surname: 'Gomez').saveLocal();
    final person = Person(name: 'Jack', familia: f1.asBelongsTo).saveLocal();
    expect(person.familia.value, equals(f1));
    expect(f1.persons.toSet(), {person});

    // server responds with an ID and an age
    container.read(responseProvider.notifier).state = TestResponse.json('''
        {"_id": "1", "name": "Jack", "age": 31}
      ''');
    // call remote save as it uses withKeyOf, relationship should be omitted
    final personUpdated = await person.save();

    expect('people#2', keyFor(personUpdated));

    // the relationship should remain intact
    expect(personUpdated.familia.value, f1);
    expect(f1.persons.toSet(), {personUpdated});
  });

  test('DataModelMixin', () async {
    final book1 = Book(id: 1, ardentSupporters: HasMany()).saveLocal();
    final book2 = Book(id: 2, ardentSupporters: HasMany()).saveLocal();
    final library =
        Library(id: 1, name: 'Babel', books: {book1, book2}.asHasMany)
            .init()
            .saveLocal();
    expect(library.books.toList(),
        unorderedEquals([book1.reloadLocal(), book2.reloadLocal()]));
  });
}
