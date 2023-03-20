import 'dart:convert';
import 'dart:io';

import 'package:flutter_data/flutter_data.dart';
import 'package:test/test.dart';

import '../_support/familia.dart';
import '../_support/person.dart';
import '../_support/setup.dart';

void main() async {
  setUp(setUpFn);
  tearDown(tearDownFn);

  test('initialization', () {
    expect(container.familia.isInitialized, isTrue);
  });

  test('findAll & clear', () async {
    final familia1 = Familia(id: '1', surname: 'Smith');
    final familia2 = Familia(id: '2', surname: 'Jones');

    container.read(responseProvider.notifier).state = TestResponse.text('''
        [{ "id": "1", "surname": "Smith" }, { "id": "2", "surname": "Jones" }]
      ''');
    final familia = await container.familia.findAll();
    await oneMs();

    expect(familia, [familia1, familia2]);

    await container.familia.clear();
    expect(await container.familia.findAll(remote: false), isEmpty);

    expect(container.familia.type, 'familia');
  });

  test('findAll with and without syncLocal', () async {
    final familia1 = Familia(id: '1', surname: 'Smith');
    final familia2 = Familia(id: '2', surname: 'Jones');

    container.read(responseProvider.notifier).state = TestResponse.text('''
        [{ "id": "1", "surname": "Smith" }, { "id": "2", "surname": "Jones" }]
      ''');
    final familia1all = await container.familia.findAll();

    expect(familia1all, [familia1, familia2]);

    container.read(responseProvider.notifier).state = TestResponse.text('''
        [{ "id": "1", "surname": "Smith" }]
      ''');
    final familia2all = await container.familia.findAll(syncLocal: false);

    expect(familia2all, [familia1]);

    // since `syncLocal: false` and `familia2` was present from an older call, it remains in local storage
    expect(
        await container.familia.findAll(remote: false), [familia1, familia2]);

    final familia3 = await container.familia.findAll(syncLocal: true);

    expect(familia3, [familia1]);

    // using `syncLocal: true` the result is equal to the contents of local storage
    expect(await container.familia.findAll(remote: false), familia3);
  });

  test('findAll in background', () async {
    container.read(responseProvider.notifier).state = TestResponse.text('''
        [{ "id": "1", "surname": "Smith" }, { "id": "2", "surname": "Jones" }]
      ''');
    final familias = await container.familia.findAll(background: true);
    expect(familias, isEmpty);

    await oneMs();

    final familias2 = await container.familia.findAll(remote: false);
    expect(familias2, hasLength(2));
  });

  test('findAll with error', () async {
    expect(() async {
      container.read(responseProvider.notifier).state = TestResponse(
          (_) async => '''&*@~&^@^&!(@*(@#{ "id": "1", "surname": "Smith" }''',
          statusCode: 203);
      await container.familia.findAll();
    }, throwsA(isA<DataException>()));

    await container.familia.findAll(
      // ignore: missing_return
      onError: (e, _, __) {
        expect(e, isA<DataException>());
        return null;
      },
    );
  });

  test('findOne', () async {
    container.read(responseProvider.notifier).state = TestResponse.text('''
        { "id": "1", "surname": "Smith" }
      ''');
    final familia = await container.familia.findOne('1');
    expect(familia, Familia(id: '1', surname: 'Smith'));

    // and it can be found again locally
    expect(familia, await container.familia.findOne('1', remote: false));
  });

  test('findOne with empty (non-null) ID works', () async {
    container.read(responseProvider.notifier).state = TestResponse.text('''
        { "id": "", "surname": "Smith" }
      ''');
    final familia = await container.familia.findOne('');
    expect(familia, isNotNull);

    // and it can be found again locally
    expect(familia, await container.familia.findOne('', remote: false));
  });

  test('findOne with changing IDs works', () async {
    container.read(responseProvider.notifier).state = TestResponse.text('''
        { "id": "97", "surname": "Smith" }
      ''');
    // query for ID=1 but receive ID=97
    final familia = await container.familia.findOne('1');
    expect(familia, isNotNull);

    // and it can be found again locally with its new ID=97
    expect(familia, await container.familia.findOne('97', remote: false));
  });

  test('findOne with empty response', () async {
    container.read(responseProvider.notifier).state = TestResponse.text('');
    final familia = await container.familia.findOne('1');
    expect(familia, isNull);
  });

  test('findOne with includes', () async {
    container.read(responseProvider.notifier).state = TestResponse.text('''
        { "id": "1", "surname": "Smith", "persons": [{"_id": "1", "name": "Stan", "age": 31}] }
      ''');
    final familia =
        await container.familia.findOne('1', params: {'include': 'people'});
    expect(familia, Familia(id: '1', surname: 'Smith'));

    // can be found again locally
    expect(familia, await container.familia.findOne('1', remote: false));

    // as well as the included Person
    expect(await container.people.findOne('1', remote: false),
        Person(id: '1', name: 'Stan', age: 31));
  });

  test('findOne in background', () async {
    container.read(responseProvider.notifier).state = TestResponse.text('''
        { "id": "1", "surname": "Smith" }
      ''');
    final familia = await container.familia.findOne('1', background: true);
    expect(familia, isNull);

    await oneMs();

    final familia2 = await container.familia.findOne('1', remote: false);
    expect(familia2, Familia(id: '1', surname: 'Smith'));
  });

  test('findOne with errors', () async {
    final error203 = isA<DataException>()
        .having((e) => e.error, 'error', isA<FormatException>())
        .having((e) => e.statusCode, 'status code', 203);

    expect(() async {
      container.read(responseProvider.notifier).state = TestResponse(
          (_) async => '''&*@~&^@^&!(@*(@#{ "id": "1", "surname": "Smith" }''',
          statusCode: 203);
      await container.familia.findOne('1');
    }, throwsA(error203));

    await oneMs();

    // ignore: missing_return
    await container.familia.findOne(
      '1',
      onError: (e, _, __) {
        expect(e, error203);
        return null;
      },
    );
  });

  test('not found does not throw by default', () async {
    expect(() async {
      container.read(responseProvider.notifier).state = TestResponse(
          (_) async => '{ "error": "not found" }',
          statusCode: 404);
      await container.familia.findOne('2');
    }, returnsNormally);

    // no record locally
    expect(await container.familia.findOne('1', remote: false), isNull);

    // now throws with overriden onError

    expect(() async {
      container.read(responseProvider.notifier).state = TestResponse(
          (_) async => '{ "error": "not found" }',
          statusCode: 404);
      await container.familia.findOne('2', onError: (e, _, __) => throw e);
    },
        throwsA(isA<DataException>().having(
          (e) => e.error,
          'error',
          {'error': 'not found'},
        ).having((e) => e.statusCode, 'status code', 404)));

    // no record locally
    expect(await container.familia.findOne('1', remote: false), isNull);
  });

  test('socket exception does not throw by default', () async {
    container.read(responseProvider.notifier).state =
        TestResponse((_) => throw SocketException('unreachable'));
    await container.familia.findOne(
      'error',
      onError: (e, _, __) {
        expect(e, isA<OfflineException>());
        return null;
      },
    );
  });

  test('save', () async {
    // familia with id=1 does not exist
    expect(await container.familia.findOne('1', remote: false), isNull);

    // with empty response
    final familia = Familia(id: '1', surname: 'Smith');
    container.read(responseProvider.notifier).state = TestResponse.text('');
    await container.familia.save(familia);

    // and it can be found again locally
    expect(familia, await container.familia.findOne('1', remote: false));

    // with non-empty response
    container.read(responseProvider.notifier).state =
        TestResponse.text('{"id": "2", "surname": "Jones Saved"}');
    await container.familia.save(Familia(id: '2', surname: 'Jones'));

    // and it can be found again locally
    final familia2 = await container.familia.findOne('2', remote: false);
    expect(familia2!.surname, 'Jones Saved');
  });

  test('delete', () async {
    final person = Person(id: '1', name: 'John', age: 21).saveLocal();
    // it does have a key
    expect(keyFor(person), isNotNull);

    // now delete
    container.read(responseProvider.notifier).state = TestResponse.text('');
    await container.people.delete(person.id!, remote: true);

    // so fetching by id again is null
    expect(await container.people.findOne(person.id!), isNull);
  });

  test('remote can return a different ID', () async {
    Familia(id: '1', surname: 'Corleone');
    Familia(id: '2', surname: 'Moletto');

    // returns 2, not the requested 1
    container.read(responseProvider.notifier).state =
        TestResponse.text('''{"id": "2", "surname": "Oslo"}''');
    await container.familia.findOne('1');
    // (no model will show up in a watchOneNotifier('1') situation)

    // 1 was requested, but finally 2 was updated
    expect(await container.familia.findOne('2', remote: false),
        Familia(id: '2', surname: 'Oslo'));
  });

  test('save with no ID should assign server ID', () async {
    final family = Familia(surname: 'Corleone');

    container.read(responseProvider.notifier).state = TestResponse.text('''
      {"id": "95", "surname": "Corleone"}''');

    final updatedFamily = await family.save();

    expect(keyFor(family), keyFor(updatedFamily));
    expect(await container.familia.remoteAdapter.findAll(remote: false),
        hasLength(1));
  });

  test('custom with auto deserialization', () async {
    container.read(responseProvider.notifier).state =
        TestResponse.text('[{"id": "19", "surname": "Pandan"}]');

    final f1 = await container.familia.remoteAdapter.sendRequest<Familia>(
      '/family'.asUri,
      method: DataRequestMethod.POST,
      body: json.encode({'a': 2}),
      label: DataRequestLabel('custom', type: 'familia'),
    );
    expect(f1, Familia(id: '19', surname: 'Pandan'));
  });

  test('custom login adapter with repo extension', () async {
    // this crappy login uses password as token
    container.read(responseProvider.notifier).state =
        TestResponse.text('''{ "token": "zzz1" }''');

    final token = await container.people.personLoginAdapter
        .login('email@email.com', 'zzz1');
    expect(token, 'zzz1');
  });

  test('custom login adapter with custom onError', () async {
    // sending a null email will trigger an error
    // and custom onError will throw an UnsupportedError
    // (instead of the standard DataException)
    expect(() async {
      container.read(responseProvider.notifier).state =
          TestResponse.text('''&*@%%*#@!''');
      await container.people.personLoginAdapter.login(null, null);
    }, throwsA(isA<UnsupportedError>()));

    await container.people.genericDoesNothingAdapter.doNothing(null, 1);
  });

  test('logging', overridePrint(() async {
    container.read(responseProvider.notifier).state = TestResponse.text('''
      [
        {"id": "1", "name": "Jackson"},
        {"id": "2", "name": "Ada"},
        {"id": "3", "name": "Bowie"},
        {"id": "4", "name": "Sandy"},
        {"id": "5", "name": "Zoe"},
        {"id": "6", "name": "Peter"},
        {"id": "7", "name": "Aldo"}
      ]''');

    final dogs = await container.dogs.findAll(params: {'a': 1}, remote: true);

    var regexp = RegExp(r'^\d\d:\d\d\d \[findAll\/dogs@[a-z0-9]{6}\]');
    expect(logging.first, matches(regexp));
    expect(
        logging.first,
        endsWith(
            'requesting [HTTP GET] https://override-base-url-in-adapter/dogs?a=1'));
    expect(logging.last, matches(regexp));
    expect(logging.last,
        endsWith('{1, 2, 3, 4, 5} (and 2 more) fetched from remote'));

    logging.clear();

    await container.dogs.save(dogs!.toList()[2], remote: false);

    regexp = RegExp(r'^\d\d:\d\d\d \[save\/dogs#3@[a-z0-9]{6}\]');
    expect(logging.first, matches(regexp));
    expect(logging.first, endsWith('saved in local storage only'));

    logging.clear();

    await container.dogs.delete('3', remote: true);

    regexp = RegExp(r'^\d\d:\d\d\d \[delete\/dogs#3@[a-z0-9]{6}\]');
    expect(logging.first, matches(regexp));
    expect(
        logging.first,
        endsWith(
            'requesting [HTTP DELETE] https://override-base-url-in-adapter/dogs/3'));
    expect(logging.last, matches(regexp));
    expect(logging.last, endsWith('deleted in local storage and remote'));

    logging.clear();

    try {
      container.read(responseProvider.notifier).state =
          TestResponse((_) async => '^@!@#(#(@#)#@', statusCode: 500);
      await container.dogs.findOne('1', remote: true);
    } catch (_) {
      expect(logging.last, contains('FormatException'));
    }

    logging.clear();

    final label = DataRequestLabel('misc', type: 'dogs');
    container.dogs.log(label, 'message');
    expect(logging.first, contains('message'));
  }));

  test('find one with utf8 characters', () async {
    container.read(responseProvider.notifier).state = TestResponse(
      (req) async => '{ "id": "1", "surname": "عمر" }',
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
    final familia = await container.familia.findOne(1);

    expect(familia, Familia(id: '1', surname: 'عمر'));
  });

  test('dispose', () {
    container.familia.dispose();
    expect(container.familia.isInitialized, isFalse);
  });
}
