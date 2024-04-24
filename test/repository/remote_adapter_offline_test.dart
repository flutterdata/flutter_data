import 'dart:convert';
import 'dart:io';

import 'package:flutter_data/flutter_data.dart';
import 'package:test/test.dart';

import '../_support/familia.dart';
import '../_support/house.dart';
import '../_support/setup.dart';

void main() async {
  setUp(setUpFn);
  tearDown(tearDownFn);

  test('watchAllNotifier/findAll and findOne', () async {
    // cause network issue
    container.read(responseProvider.notifier).state = TestResponse((_) {
      throw HandshakeException('Connection terminated during handshake');
    });

    // watch
    final notifier = container.bookAuthors.watchAllNotifier(remote: true);
    final tester = notifier.tester();

    // now try to findOne
    container.bookAuthors.findOne(19);

    // and verify onError does capture the `OfflineException`
    await tester.expectDataState([],
        isLoading: isFalse,
        exception: isA<Exception>()
            .having((e) => e.toString(), 'e', startsWith('OfflineException:')));

    // assert there are no queued operations for findOne
    // because it is a GET operation
    expect(
        container.bookAuthors.offlineOperations
            .only(DataRequestLabel('findOne', type: 'bookAuthors')),
        isEmpty);

    // now make the response a success
    container.read(responseProvider.notifier).state =
        TestResponse.json('{"id": 19, "name": "Author Saved"}');

    // try findOne again this time without errors
    final model = await container.bookAuthors.findOne(19);
    expect(model!.name, equals('Author Saved'));
    expect(container.familia.offlineOperations, isEmpty);
  });

  test('save', () async {
    // listening to local changes is enough
    final notifier = container.familia.watchAllNotifier(remote: false);
    final tester = notifier.tester();

    // sample house
    final residence = House(address: '789 Long Rd').saveLocal();

    // sample familia
    final familia =
        Familia(id: '1', surname: 'Smith', residence: residence.asBelongsTo)
            .saveLocal();

    // network issue persisting familia
    container.read(responseProvider.notifier).state =
        TestResponse((_) => throw SocketException('unreachable'));

    // NOTE: keep await, so that we give onError the chance to update the notifier
    await container.familia.save(
      familia,
      // override headers & params
      headers: {'X-Override-Name': 'Mantego'},
      params: {'overrideSecondName': 'Zorrilla'},
      // ignore: missing_return
      onError: (e, _, __) async {
        // supply onError for exception to show up in notifier
        notifier.updateWith(exception: e);
        return null;
      },
      onSuccess: (data, label, adapter) async {
        final model = await adapter.onSuccess<Familia>(data, label);
        // the surname follows `X-Override-Name` + `overrideSecondName`
        // as the save has been replayed with the original headers/params
        final f2 = Familia(id: '1', surname: 'Mantego Zorrilla');
        expect(model, equals(f2));
        expect(model!.residence.value, residence);
        expect(residence.owner.value, f2);
        return model;
      },
    );

    // assert it's an OfflineException
    await tester.expectDataState(hasLength(1),
        exception: isA<OfflineException>());

    // familia is remembered as failed to persist
    expect(
        container.familia.offlineOperations
            .only(DataRequestLabel('save', type: 'familia'))
            .map((o) => o.label.id)
            .toList(),
        [familia.id]);

    // try with familia2 (tests it can work without ID)
    final familia2 = Familia(surname: 'Montewicz');
    try {
      await container.familia.save(familia2);
    } catch (_) {
      // without onError, ignore exception
    }

    // now two familia failed to persist
    expect(
        container.familia.offlineOperations
            .only(DataRequestLabel('save', type: 'familia'))
            .map((o) => o.label.id)
            .toList(),
        unorderedEquals([familia.id, familia2.id]));

    // retry saving both
    await container.familia.offlineOperations.retry();

    // none of them could be saved upon retry
    expect(container.familia.offlineOperations.map((o) {
      return o.model;
    }), unorderedEquals([familia, familia2]));

    // change the response to: success for familia, failure for familia2
    container.read(responseProvider.notifier).state = TestResponse(
      (req) async {
        if (req.url.pathSegments.last == '1') {
          return '{"id": "1", "surname": "${req.headers['X-Override-Name']} ${req.url.queryParameters['overrideSecondName']}"}';
        }
        throw SocketException('unreachable');
      },
    );

    // retry
    await container.familia.offlineOperations.retry();

    // familia2 failed on retry, operation still pending
    expect(container.familia.offlineOperations.map((o) => o.model),
        equals([familia2]));

    // change response to success for both familia and familia2
    container.read(responseProvider.notifier).state = TestResponse(
      (req) async {
        return '{"id": "${req.url.pathSegments.last}", "surname": "Jones ${req.url.pathSegments.last}"}';
      },
    );

    // retry
    await container.familia.offlineOperations.retry();

    // should be empty as all saves succeeded
    expect(container.familia.offlineOperations.map((o) => o.model), isEmpty);

    // simulate a network issue once again for familia3
    container.read(responseProvider.notifier).state =
        TestResponse((_) => throw SocketException('unreachable'));

    final familia3 = Familia(id: '3', surname: 'Zweck');
    try {
      await familia3.save();
    } catch (_) {
      // without onError, ignore exception
    }

    // assert familia3 hasn't been persisted
    expect(
        container.familia.offlineOperations
            .only(DataRequestLabel('save', type: 'familia'))
            .map((o) => o.model),
        [familia3]);

    // use `reset` to forget/ignore failed to save models
    container.familia.offlineOperations.reset();

    // so it's empty again
    expect(
        container.familia.offlineOperations
            .only(DataRequestLabel('save', type: 'familia'))
            .map((o) => o.model),
        isEmpty);
  });

  test('delete', () async {
    // listening to local changes is enough
    final notifier = container.familia.watchAllNotifier();
    final tester = notifier.tester();

    final familia = Familia(id: '1', surname: 'Smith').saveLocal();

    // should show up through watchAllNotifier
    await tester.expectDataState([familia]);

    // network issue deleting familia
    container.read(responseProvider.notifier).state = TestResponse((_) {
      throw SocketException('unreachable');
    });

    // delete familia and send offline exception to notifier
    // NOTE: keep await, so that we give onError the chance to update the notifier
    await familia.delete(
      onError: (e, _, __) async {
        expect(e, isA<OfflineException>());
        expect(e.error, isA<SocketException>());
        return null;
      },
    );

    // verify the model in local storage has been deleted
    await tester.expectDataState(isEmpty);

    // familia is remembered as failed to persist
    expect(
        container.familia.offlineOperations
            .only(DataRequestLabel('delete', type: 'familia'))
            .map((o) => o.label.id),
        ['1']);

    // retry
    await container.familia.offlineOperations.retry();

    // could not be deleted upon retry
    expect(
        container.familia.offlineOperations
            .only(DataRequestLabel('delete', type: 'familia'))
            .map((o) => o.label.id),
        ['1']);

    // change the response to success
    container.read(responseProvider.notifier).state = TestResponse.json('');

    // retry
    await container.familia.offlineOperations.retry();

    // now offline queue is empty
    expect(container.familia.offlineOperations, isEmpty);
  });

  test('save & delete combined', () async {
    // listening to local changes enough
    final notifier = container.familia.watchAllNotifier(remote: false);
    final tester = notifier.tester();

    // setup familia
    final familia = Familia(id: '19', surname: 'Ko');

    // network issues
    container.read(responseProvider.notifier).state = TestResponse((_) {
      throw SocketException('unreachable');
    });

    // save
    await familia.save(
      headers: {'X-Override-Name': 'Johnson'},
      onError: (e, _, __) async {
        notifier.updateWith(exception: e);
        return null;
      },
    );

    // immediately delete
    await familia.delete(
      onError: (e, _, __) async {
        notifier.updateWith(exception: e);
        return null;
      },
    );

    // assert it's an OfflineException
    tester.expectDataState(isNotNull, exception: isA<OfflineException>());

    // should see the failed save queued
    expect(
        container.familia.offlineOperations
            .only(DataRequestLabel('save', type: 'familia'))
            .map((o) => o.label.id)
            .toList(),
        [familia.id]);

    // clearly the local model was deleted, so the associated
    // model should be null
    expect(
        container.familia.offlineOperations
            .only(DataRequestLabel('save', type: 'familia'))
            .map((o) => o.model)
            .toList(),
        [null]);

    // should see the failed delete queued
    expect(
        container.familia.offlineOperations
            .only(DataRequestLabel('delete', type: 'familia'))
            .map((o) => o.label.id)
            .toList(),
        ['19']);

    // retry
    await container.familia.offlineOperations.retry();

    // same result
    expect(container.familia.offlineOperations, hasLength(2));

    // change the response to success
    container.read(responseProvider.notifier).state = TestResponse.json('');

    // retry
    await container.familia.offlineOperations.retry();

    // done
    expect(container.familia.offlineOperations, isEmpty);
  });

  test('custom request with body', () async {
    // network issue
    container.read(responseProvider.notifier).state = TestResponse((_) {
      throw SocketException('unreachable');
    });

    // random endpoint with random headers
    await container.familia.sendRequest<Familia>(
      '/fam'.asUri,
      method: DataRequestMethod.POST,
      headers: {'X-Sats': '9389173717732'},
      body: json.encode({'a': 2}),
      onSuccess: (data, label) async {
        final result = await container.familia.onSuccess<Familia>(data, label);
        expect(
            data.body,
            equals([
              {'id': '19', 'surname': 'Ko Saved'}
            ]));
        return result;
      },
    );
    // fails to go through
    expect(container.familia.offlineOperations, hasLength(1));

    // return a success response
    container.read(responseProvider.notifier).state = TestResponse(
      (req) async {
        // assert headers are included in the retry
        expect(req.headers['X-Sats'], equals('9389173717732'));
        expect(json.decode(req.body), {'a': 2});
        return '[{"id": "19", "surname": "Ko Saved"}]';
      },
    );

    // retry
    await container.familia.offlineOperations.retry();

    // done
    expect(container.familia.offlineOperations, isEmpty);
  });

  test('operation equality', () {
    final o1 = OfflineOperation<Familia>(
      label: DataRequestLabel('findAll', type: 'familia', requestId: 'test'),
      httpRequest: 'GET /familia',
      timestamp: 1,
      headers: {'X-Header': 'dang'},
      adapter: container.familia,
    );

    final o2 = OfflineOperation<Familia>(
      label: DataRequestLabel('findAll', type: 'familia', requestId: 'test'),
      httpRequest: 'GET /familia',
      timestamp: 1,
      headers: {'X-Header': 'dang'},
      adapter: container.familia,
    );

    expect(o1, equals(o2));
  });

  test('findOne scenario issue #118', () async {
    // cause network issue
    container.read(responseProvider.notifier).state = TestResponse((_) {
      throw HandshakeException('Connection terminated during handshake');
    });

    final familia1 = await container.familia.findOne('1', remote: false);
    expect(familia1, isNull);

    container.read(responseProvider.notifier).state = TestResponse.json('''
        { "id": "1", "surname": "Smith" }
      ''');
    await container.familia.findOne('1');

    // cause network issue
    container.read(responseProvider.notifier).state = TestResponse((_) {
      throw HandshakeException('Connection terminated during handshake');
    });

    final familia2 = await container.familia.findOne('1', remote: false);
    expect(familia2, isNotNull);
  });
}
