import 'dart:convert';
import 'dart:io';

import 'package:flutter_data/flutter_data.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../_support/family.dart';
import '../_support/setup.dart';
import '../mocks.dart';

void main() async {
  setUp(setUpFn);
  tearDown(tearDownFn);

  test('save offline', () async {
    final listener = Listener<DataState<List<Family>>>();
    // listening to local changes enough
    final notifier = familyRepository.watchAll(remote: false);

    dispose = notifier.addListener(listener, fireImmediately: true);

    final family = Family(id: '1', surname: 'Smith');

    // network issue persisting family
    container.read(responseProvider).state =
        TestResponse(text: (_) => throw SocketException('unreachable'));

    // must specify remote=true as repo's default is remote=false
    await familyRepository.save(
      family,
      remote: true,
      headers: {'X-Override-Name': 'Mantego'},
      params: {'overrideSecondName': 'Zorrilla'},
      onError: (e) async {
        // supply onError for exception to show up in notifier
        await oneMs();
        notifier.updateWith(exception: e);
      },
      onSuccess: (model) {
        // the surname follows `X-Override-Name` + `overrideSecondName`
        // as the save has been replayed with the original headers/params
        expect(model, equals(Family(id: '1', surname: 'Mantego Zorrilla')));
        return model;
      },
    );
    await oneMs();

    // assert it's an OfflineException
    verify(listener(argThat(
      isA<DataState<List<Family>>>().having(
        (s) {
          return s.exception;
        },
        'exception',
        isA<OfflineException>().having(
          (s) => s.model,
          'model',
          equals(family),
        ),
      ),
    ))).called(1);

    // family is remembered as failed to persist
    expect(familyRepository.offlineSaved, [family]);

    // try with family2
    final family2 = Family(id: '2', surname: 'Montewicz');
    try {
      await familyRepository.save(family2, remote: true);
    } catch (_) {
      // without onError, ignore exception
    }
    await oneMs();

    // now two families failed to persist
    expect(familyRepository.offlineSaved, [family, family2]);

    // retry saving them
    final exceptions = await familyRepository.offlineSync();
    // await 1ms for each family
    await oneMs();
    await oneMs();

    // none of them could be saved upon retry - we get two OfflineExceptions again
    expect(exceptions.map((e) => (e as OfflineException).model),
        equals([family, family2]));

    // change the response to: success for family, failure for family2
    container.read(responseProvider).state = TestResponse(
      text: (req) {
        if (req.url.pathSegments.last == '1') {
          return '{"id": "1", "surname": "${req.headers['X-Override-Name']} ${req.url.queryParameters['overrideSecondName']}"}';
        }
        throw SocketException('unreachable');
      },
    );

    // retry
    final exceptions2 = await familyRepository.offlineSync();
    await oneMs();
    await oneMs();

    // the returned OfflineException still points to family2, failed on retry
    expect(exceptions2.map((e) => (e as OfflineException).model), [family2]);

    // family2 still remembered as not persisted
    expect(familyRepository.offlineSaved, [family2]);

    // change response to success for both family and family2
    container.read(responseProvider).state = TestResponse(text: (req) {
      return '{"id": "${req.url.pathSegments.last}", "surname": "Jones ${req.url.pathSegments.last}"}';
    });

    // retry
    final exceptions3 = await familyRepository.offlineSync();
    await oneMs();
    await oneMs();

    // should be empty as all saves succeeded
    expect(exceptions3.map((e) => (e as OfflineException).model), isEmpty);

    // same here
    expect(familyRepository.offlineSaved, isEmpty);

    // simulate a network issue once again for family3
    container.read(responseProvider).state =
        TestResponse(text: (_) => throw SocketException('unreachable'));

    try {
      await Family(id: '3', surname: 'Zweck')
          .init(container.read)
          .save(remote: true);
    } catch (_) {
      // without onError, ignore exception
    }
    await oneMs();

    // assert family3 hasn't been persisted
    expect(familyRepository.offlineSaved,
        equals([Family(id: '3', surname: 'Zweck')]));

    // use `resetOfflineModels` to forget/ignore failed to save models
    familyRepository.offlineClear();

    // so it's empty again
    expect(familyRepository.offlineSaved, isEmpty);

    // we know that a node will be created with the JSON contents
    // of headers and params - assert it's been removed

    final _json = json.encode({'X-Override-Name': 'Mantego'});

    // ignore: invalid_use_of_protected_member
    expect(familyRepository.remoteAdapter.graph.toMap().keys,
        isNot(contains(_json)));
  });

  test('delete offline', () async {
    final listener = Listener<DataState<List<Family>>>();
    // listening to local changes enough
    final notifier = familyRepository.watchAll(remote: false);

    dispose = notifier.addListener(listener, fireImmediately: true);

    final family = Family(id: '1', surname: 'Smith').init(container.read);
    await oneMs();

    verify(listener(
      argThat(isA<DataState<List<Family>>>()
          .having((s) => s.model, 'model', [family])),
    )).called(1);

    // network issue deleting family
    container.read(responseProvider).state = TestResponse(text: (_) {
      throw SocketException('unreachable');
    });

    await family.delete(
      remote: true,
      onError: (e) async {
        notifier.updateWith(exception: e);
      },
    );

    verify(listener(
      argThat(isA<DataState<List<Family>>>()
          .having((s) => s.model, 'model', isEmpty)),
    )).called(1);

    // assert it's an OfflineException
    verify(listener(argThat(
      isA<DataState<List<Family>>>()
          .having((s) => s.exception, 'exception', isA<OfflineException>()),
    ))).called(1);

    // family is remembered as failed to persist
    expect(familyRepository.offlineDeleted, ['1']);

    // retry deleting them
    final exceptions = await familyRepository.offlineSync();
    await oneMs();

    // could not be deleted upon retry - we get an OfflineException again
    expect(exceptions.map((e) => (e as OfflineException).id), ['1']);

    // change the response to: success for family
    container.read(responseProvider).state = TestResponse.text('');

    // retry deleting
    final exceptions2 = await familyRepository.offlineSync();
    await oneMs();

    expect(exceptions2, isEmpty);
  });

  test('save & delete offline & sync', () async {
    final listener = Listener<DataState<List<Family>>>();
    // listening to local changes enough
    final notifier = familyRepository.watchAll(remote: false);

    dispose = notifier.addListener(listener, fireImmediately: true);

    final family = Family(id: '19', surname: 'Ko').init(container.read);
    await oneMs();

    // network issue persisting family
    container.read(responseProvider).state = TestResponse(text: (_) {
      throw SocketException('unreachable');
    });

    // save...
    await family.save(
      remote: true,
      headers: {'X-Override-Name': 'Johnson'},
      onError: (e) async {
        notifier.updateWith(exception: e);
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

    // assert it's an OfflineException
    verify(listener(argThat(
      isA<DataState<List<Family>>>()
          .having((s) => s.exception, 'exception', isA<OfflineException>()),
    ))).called(2); // one call per updateWith(e)

    // should see a model here because of the failed save
    // but the model was also deleted
    expect(familyRepository.offlineSaved, isEmpty);

    // and here is its id
    expect(familyRepository.offlineDeleted, ['19']);

    // retry sync
    final exceptions2 = await familyRepository.offlineSync();
    await oneMs();
    expect(exceptions2, hasLength(1));

    // change the response to: success for family
    container.read(responseProvider).state = TestResponse.text('');

    // retry sync
    final exceptions3 = await familyRepository.offlineSync();
    await oneMs();
    // done
    expect(exceptions3, isEmpty);

    // we know that a node will be created with the JSON contents
    // of headers and params - assert it's been removed

    // final _json = json.encode({'X-Override-Name': 'Johnson'});

    // // ignore: invalid_use_of_protected_member
    // expect(familyRepository.remoteAdapter.graph.toMap().keys,
    //     isNot(contains(_json)));
  });
}
