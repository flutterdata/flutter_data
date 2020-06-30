import 'dart:async';
import 'dart:io';

import 'package:flutter_data/flutter_data.dart';
import 'package:test/test.dart';

import '../models/models.dart';
import '../unit/mocks.dart';
import 'server.dart';

final injection = DataServiceLocator();

void main() async {
  HttpServer server;
  Function dispose;
  DataManager manager;

  setUpAll(() async {
    server = await createServer(InternetAddress.loopbackIPv4, 17083);
    injection.register(HiveMock());
    manager = TestDataManager(injection.locator);
    injection.register<DataManager>(manager);

    // we use $CompanyRepository as it already has the TestMixin baked in
    injection.register<Repository<Company>>(
        $CompanyRepository(manager, box: FakeBox<Company>(), verbose: false));
    injection.register<Repository<City>>(
        CityTestRepository(manager, box: FakeBox<City>(), verbose: false));
    injection.register<Repository<Model>>(
        ModelTestRepository(manager, box: FakeBox<Model>(), verbose: false));
  });

  tearDown(() {
    dispose?.call();
  });

  test('findAll', () async {
    final repo = manager.locator<Repository<City>>();
    final cities = await repo.findAll(params: {
      'page': {'offset': 1}
    });
    expect(cities.first.isNew, false);
    expect(cities.first.name, 'Munich');
    expect(cities.length, 3);

    final citiesFromLocal = await repo.findAll(remote: false);
    expect(citiesFromLocal.first.isNew, false);
  });

  test('findOne with include', () async {
    final repo = manager.locator<Repository<Company>>();
    final company = await repo.findOne('1', params: {'include': 'models'});
    expect(company.models.last.name, 'Model 3');
  });

  test('watchOne', () async {
    final modelRepo = manager.locator<Repository<Model>>();
    final notifier = modelRepo.watchOne('1');

    dispose = notifier.addListener(
      expectAsync1((state) {
        expect(state.model.name, equals('Roadster'));
      }),
      fireImmediately: false,
    );
  });

  test('save', () async {
    final repo = manager.locator<Repository<Model>>();
    await repo.box.clear();
    final companyRepo = manager.locator<Repository<Company>>();

    final company = await companyRepo.findOne(4, params: {'include': 'models'});
    expect(await repo.findAll(), hasLength(7));

    final m = Model(id: '3', name: 'Elon X', company: company.asBelongsTo)
        .init(manager: manager);
    final m1 = await m.save();
    final m2 = await repo.findOne('3');

    expect(m.id, m1.id);
    expect(m.id, m2.id);

    expect(keyFor(m1), keyFor(m2));
    expect(keyFor(m), keyFor(m2));
    expect(m2.name, 'Elon X');

    // following assertion won't pass as server data
    // "loses" information (returns 0 relationships)
    // expect(m2.company.value, c);

    // create a model, persist in server, remove local copy
    final k = await Model(name: 'K').init(manager: manager).save();
    await k.delete(remote: false);

    // since model repo has `shouldLoadRemoteAll` set to false
    // if models exist locally --
    // there are now 8 models on the server, but locally we know of 7
    expect(await repo.findAll(), hasLength(7));
  });

  test('save without id', () async {
    final repo = manager.locator<Repository<Company>>();
    final company =
        Company(name: 'New Co', models: HasMany()).init(manager: manager);

    final c2 = await company.save();
    expect(c2.id, isNotNull);
    expect(keyFor(company), keyFor(c2));

    final c3 = await repo.findOne(c2.id);
    expect(c2.name, company.name);
    expect(c3.name, c2.name);
    expect(keyFor(c2), keyFor(c3));
  });

  test('save after adding to rel', () async {
    final repo = manager.locator<Repository<Company>>();
    final company = await repo.findOne('1');

    final model =
        Model(name: 'Zucchini 8', company: BelongsTo()).init(manager: manager);
    company.models.add(model);
    final m2 = await model.save();
    expect(keyFor(model), keyFor(m2));

    final m3 =
        Model(name: 'Zucchini 93', company: BelongsTo()).init(manager: manager);
    final tempKeyM3 = keyFor(m3);
    final m4 = await m3.save();

    // saving a Model WILL ALWAYS RETURN AN ID=9217
    // => key has changed after save!
    expect(tempKeyM3, isNot(keyFor(m3)));
    expect(keyFor(m3), keyFor(m4));
  });

  test('fetch with error', () async {
    expect(() async {
      await manager.locator<Repository<Company>>().findOne('2332');
    }, throwsA(isA<DataException>()));
  });

  tearDownAll(() async {
    await server.close();
    await manager.locator<Repository<Model>>().dispose();
    injection.clear();
  });

  test('watch city', () async {
    final city = City(id: '1', name: 'Chicago').init(manager: manager);

    void changeCityName() {
      Timer.run(() => city.copyWith(name: 'Montevideo').was(city));
    }

    final notifier = city.watch();
    var i = 0;
    dispose = notifier.addListener(
      expectAsync1((state) {
        if (i == 0) {
          // initial value
          expect(state.isLoading, true);
          expect(state.model.name, 'Chicago');
        }
        if (i == 1) {
          // updated with API response
          expect(state.isLoading, false);
          expect(state.model.name, 'Munich');
          changeCityName();
        }
        if (i == 2) {
          // set by changeCityName()
          expect(state.isLoading, false);
          expect(state.model.name, 'Montevideo');
        }
        i++;
      }, count: 3),
    );
  });

  test('watch all cities', () async {
    // NOTE: CityRepository has a throttle duration set to zero!
    final repo = manager.locator<Repository<City>>();
    await repo.box.clear();

    final notifier = repo.watchAll();
    var i = 0;
    dispose = notifier.addListener(
      expectAsync1((state) {
        if (i == 0) {
          // initial value
          expect(state.isLoading, true);
          expect(state.model, isEmpty);
        }
        if (i == 1) {
          // updated with API response
          expect(state.isLoading, false);
          expect(state.model.map((city) => city.name),
              ['Munich', 'Palo Alto', 'Ingolstadt']);
        }
        i++;
      }, count: 2),
    );
  });
}
