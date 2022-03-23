import 'dart:convert';
import 'dart:io';

import 'package:flutter_data/flutter_data.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../_support/book.dart';
import '../_support/family.dart';
import '../_support/setup.dart';
import '../mocks.dart';

void main() async {
  setUp(setUpFn);
  tearDown(tearDownFn);

  test('watchAllNotifier/findAll and findOne', () async {
    // cause network issue
    container.read(responseProvider.notifier).state = TestResponse(text: (_) {
      throw HandshakeException('Connection terminated during handshake');
    });

    final listener = Listener<DataState<List<BookAuthor>>?>();

    // watch
    final notifier =
        bookAuthorRepository.remoteAdapter.watchAllNotifier(remote: true);
    dispose = notifier.addListener(listener, fireImmediately: true);

    await oneMs();

    // the internal findAll should trigger an offline operation
    expect(
        bookAuthorRepository.offlineOperations.first.offlineKey, 'bookAuthors');
    expect(bookAuthorRepository.offlineOperations.first.requestType,
        DataRequestType.findAll);

    // now try to findOne
    await bookAuthorRepository.findOne(
      19,
      remote: true,
      // ignore: missing_return
      onError: (e) async {
        notifier.updateWith(exception: e);
        return null;
      },
    );

    // and verify onError does capture the `OfflineException`
    verify(listener(argThat(
      isA<DataState>().having((s) => s.exception!.toString(), 'exception',
          startsWith('OfflineException:')),
    ))).called(1); // one call per updateWith(e)

    // retry and assert there is one queued operation for findOne
    await bookAuthorRepository.offlineOperations.retry();
    await oneMs();
    expect(bookAuthorRepository.offlineOperations.only(DataRequestType.findOne),
        hasLength(1));

    // now make the response a success
    container.read(responseProvider.notifier).state =
        TestResponse.text('{"id": 19, "name": "Author Saved"}');

    // retry and assert queue is empty
    await bookAuthorRepository.offlineOperations.retry();
    await oneMs();
    expect(bookAuthorRepository.offlineOperations, isEmpty);

    // try findOne again this time without errors
    final model = await bookAuthorRepository.findOne(19, remote: true);
    expect(model!.name, equals('Author Saved'));
    await oneMs();
    expect(familyRepository.offlineOperations, isEmpty);
  });

  test('save', () async {
    final listener = Listener<DataState<List<Family>>?>();
    // listening to local changes enough
    final notifier =
        familyRepository.remoteAdapter.watchAllNotifier(remote: false);

    dispose = notifier.addListener(listener, fireImmediately: true);

    // sample family
    final family = Family(id: '1', surname: 'Smith');

    // network issue persisting family
    container.read(responseProvider.notifier).state =
        TestResponse(text: (_) => throw SocketException('unreachable'));

    // must specify remote=true as repo's default is remote=false
    await familyRepository.save(
      family,
      // override headers & params
      headers: {'X-Override-Name': 'Mantego'},
      params: {'overrideSecondName': 'Zorrilla'},
      // ignore: missing_return
      onError: (e) async {
        // supply onError for exception to show up in notifier
        await oneMs();
        notifier.updateWith(exception: e);
        return null;
      },
      onSuccess: (model) {
        // the surname follows `X-Override-Name` + `overrideSecondName`
        // as the save has been replayed with the original headers/params
        expect(model, equals(Family(id: '1', surname: 'Mantego Zorrilla')));
        return model as Family;
      },
    );
    await oneMs();

    // assert it's an OfflineException
    verify(
      listener(
        argThat(
          isA<DataState>()
              .having((s) => s.exception, 'exception', isA<OfflineException>()),
        ),
      ),
    ).called(1);

    // family is remembered as failed to persist
    expect(
        familyRepository.offlineOperations
            .only(DataRequestType.save)
            .map((o) => o.offlineKey)
            .toList(),
        [keyFor(family)]);

    // try with family2
    final family2 = Family(id: '2', surname: 'Montewicz');
    try {
      await familyRepository.save(family2);
    } catch (_) {
      // without onError, ignore exception
    }
    await oneMs();

    // now two families failed to persist
    expect(
        familyRepository.offlineOperations
            .only(DataRequestType.save)
            .map((o) => o.offlineKey)
            .toList(),
        [keyFor(family), keyFor(family2)]);

    // retry saving both
    await familyRepository.offlineOperations.retry();
    // await 1ms for each family
    await oneMs();
    await oneMs();

    // none of them could be saved upon retry
    expect(familyRepository.offlineOperations.map((o) => o.model),
        equals([family, family2]));

    // change the response to: success for family, failure for family2
    container.read(responseProvider.notifier).state = TestResponse(
      text: (req) {
        if (req.url.pathSegments.last == '1') {
          return '{"id": "1", "surname": "${req.headers['X-Override-Name']} ${req.url.queryParameters['overrideSecondName']}"}';
        }
        throw SocketException('unreachable');
      },
    );

    // retry
    await familyRepository.offlineOperations.retry();
    await oneMs();
    await oneMs();

    // family2 failed on retry, operation still pending
    expect(familyRepository.offlineOperations.map((o) => o.model),
        equals([family2]));

    // change response to success for both family and family2
    container.read(responseProvider.notifier).state = TestResponse(text: (req) {
      return '{"id": "${req.url.pathSegments.last}", "surname": "Jones ${req.url.pathSegments.last}"}';
    });

    // retry
    await familyRepository.offlineOperations.retry();
    await oneMs();
    await oneMs();

    // should be empty as all saves succeeded
    expect(familyRepository.offlineOperations.map((o) => o.model), isEmpty);

    // simulate a network issue once again for family3
    container.read(responseProvider.notifier).state =
        TestResponse(text: (_) => throw SocketException('unreachable'));

    final family3 = Family(id: '3', surname: 'Zweck').init(container.read);
    try {
      await family3.save(remote: true);
    } catch (_) {
      // without onError, ignore exception
    }
    await oneMs();

    // assert family3 hasn't been persisted
    expect(
        familyRepository.offlineOperations
            .only(DataRequestType.save)
            .map((o) => o.model),
        [family3]);

    // use `reset` to forget/ignore failed to save models
    familyRepository.offlineOperations.reset();

    // so it's empty again
    expect(
        familyRepository.offlineOperations
            .only(DataRequestType.save)
            .map((o) => o.model),
        isEmpty);
  });

  test('delete', () async {
    final listener = Listener<DataState<List<Family>>?>();
    // listening to local changes enough
    final notifier =
        familyRepository.remoteAdapter.watchAllNotifier(remote: false);

    dispose = notifier.addListener(listener, fireImmediately: true);

    // init a family
    final family = Family(id: '1', surname: 'Smith').init(container.read);
    await oneMs();

    // should show up through watchAllNotifier
    verify(listener(
      argThat(isA<DataState>().having((s) => s.model, 'model', [family])),
    )).called(1);

    // network issue deleting family
    container.read(responseProvider.notifier).state = TestResponse(text: (_) {
      throw SocketException('unreachable');
    });

    // delete family and send offline exception to notifier
    await family.delete(
      remote: true,
      onError: (e) async {
        notifier.updateWith(exception: e);
      },
    );

    // verify the model in local storage has been deleted
    verify(listener(
      argThat(isA<DataState>().having((s) => s.model, 'model', isEmpty)),
    )).called(1);

    // and that we actually got an OfflineException
    verify(listener(argThat(
      isA<DataState>()
          .having((s) => s.exception, 'exception', isA<OfflineException>()),
    ))).called(1);

    // family is remembered as failed to persist
    expect(
        familyRepository.offlineOperations
            .only(DataRequestType.delete)
            .map((o) => o.offlineKey),
        ['families#1']);

    // retry
    await familyRepository.offlineOperations.retry();
    await oneMs();

    // could not be deleted upon retry
    expect(
        familyRepository.offlineOperations
            .only(DataRequestType.delete)
            .map((o) => o.offlineKey),
        ['families#1']);

    // change the response to success
    container.read(responseProvider.notifier).state = TestResponse.text('');

    // retry
    await familyRepository.offlineOperations.retry();
    await oneMs();

    // now offline queue is empty
    expect(familyRepository.offlineOperations, isEmpty);
  });

  test('save & delete combined', () async {
    final listener = Listener<DataState<List<Family>>?>();
    // listening to local changes enough
    final notifier =
        familyRepository.remoteAdapter.watchAllNotifier(remote: false);

    dispose = notifier.addListener(listener, fireImmediately: true);

    // setup family
    final family = Family(id: '19', surname: 'Ko').init(container.read);
    await oneMs();

    // network issues
    container.read(responseProvider.notifier).state = TestResponse(text: (_) {
      throw SocketException('unreachable');
    });

    // save...
    await family.save(
      remote: true,
      headers: {'X-Override-Name': 'Johnson'},
      // ignore: missing_return
      onError: (e) async {
        notifier.updateWith(exception: e);
        return null;
      },
    );

    await oneMs();

    // ...and immediately delete
    await family.delete(
      remote: true,
      onError: (e) async {
        notifier.updateWith(exception: e);
      },
    );

    await oneMs();

    // assert it's an OfflineException, TWICE (one call per updateWith(e))
    verify(listener(argThat(
      isA<DataState>()
          .having((s) => s.exception, 'exception', isA<OfflineException>()),
    ))).called(2);

    // should see the failed save queued
    expect(
        familyRepository.offlineOperations
            .only(DataRequestType.save)
            .map((o) => o.offlineKey)
            .toList(),
        [keyFor(family)]);

    // clearly the local model was deleted, so the associated
    // model should be null
    expect(
        familyRepository.offlineOperations
            .only(DataRequestType.save)
            .map((o) => o.model)
            .toList(),
        [null]);

    // should see the failed delete queued
    expect(
        familyRepository.offlineOperations
            .only(DataRequestType.delete)
            .map((o) => o.offlineKey)
            .toList(),
        ['families#19']);

    // retry
    await familyRepository.offlineOperations.retry();
    await oneMs();
    // same result...
    expect(familyRepository.offlineOperations, hasLength(2));

    // change the response to success
    container.read(responseProvider.notifier).state = TestResponse.text('');

    // retry
    await familyRepository.offlineOperations.retry();
    await oneMs();
    // done
    expect(familyRepository.offlineOperations, isEmpty);
  });

  test('ad-hoc request with body', () async {
    // network issue
    container.read(responseProvider.notifier).state = TestResponse(text: (_) {
      throw SocketException('unreachable');
    });

    // random endpoint with random headers
    familyRepository.remoteAdapter.sendRequest(
      '/fam'.asUri,
      method: DataRequestMethod.POST,
      headers: {'X-Sats': '9389173717732'},
      body: json.encode({'a': 2}),
      onSuccess: (_) {
        expect(
            _,
            equals([
              {'id': '19', 'surname': 'Ko Saved'}
            ]));
      },
    );
    await oneMs();
    // fails to go through
    expect(familyRepository.offlineOperations, hasLength(1));

    // return a success response
    container.read(responseProvider.notifier).state = TestResponse(
      text: (req) {
        // assert headers are included in the retry
        expect(req.headers['X-Sats'], equals('9389173717732'));
        expect(json.decode(req.body), {'a': 2});
        return '[{"id": "19", "surname": "Ko Saved"}]';
      },
    );

    // retry
    await familyRepository.offlineOperations.retry();
    await oneMs();
    // done
    expect(familyRepository.offlineOperations, isEmpty);
  });

  test('another non-offline error should resolve the operation', () async {
    // network issue
    container.read(responseProvider.notifier).state = TestResponse(text: (_) {
      throw SocketException('unreachable');
    });
    familyRepository.remoteAdapter.sendRequest('/fam'.asUri);

    await oneMs();
    // fails to go through
    expect(familyRepository.offlineOperations, hasLength(1));

    // return a 404
    container.read(responseProvider.notifier).state =
        TestResponse(text: (_) => 'not found', statusCode: 404);

    // retry
    await familyRepository.offlineOperations.retry();
    await oneMs();
    // done
    expect(familyRepository.offlineOperations, isEmpty);
  });

  test('operation equality', () {
    final o1 = OfflineOperation<Family>(
      requestType: DataRequestType.findAll,
      offlineKey: 'families',
      request: 'GET /families',
      headers: {'X-Header': 'chupala'},
      adapter: familyRemoteAdapter,
    );

    final o2 = OfflineOperation<Family>(
      requestType: DataRequestType.findAll,
      offlineKey: 'families',
      request: 'GET /families',
      headers: {'X-Header': 'chupala'},
      adapter: familyRemoteAdapter,
    );

    expect(o1, equals(o2));
    expect(o1.hash, equals(o2.hash));
  });

  test('findOne scenario issue #118', () async {
    // cause network issue
    container.read(responseProvider.notifier).state = TestResponse(text: (_) {
      throw HandshakeException('Connection terminated during handshake');
    });

    final family1 = await familyRepository.findOne('1', remote: false);
    expect(family1, isNull);

    container.read(responseProvider.notifier).state = TestResponse.text('''
        { "id": "1", "surname": "Smith" }
      ''');
    await familyRepository.findOne('1', remote: true);

    // cause network issue
    container.read(responseProvider.notifier).state = TestResponse(text: (_) {
      throw HandshakeException('Connection terminated during handshake');
    });

    final family2 = await familyRepository.findOne('1', remote: false);
    expect(family2, isNotNull);
  });
}
