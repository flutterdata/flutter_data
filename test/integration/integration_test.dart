import 'dart:io';

import 'package:flutter_data/flutter_data.dart';
import 'package:test/test.dart';

import '../models/models.dart';
import '../unit/setup.dart';
import 'server.dart';

final injection = DataServiceLocator();

void main() async {
  HttpServer server;
  Function dispose;

  setUpAll(() async {
    server = await createServer(InternetAddress.loopbackIPv4, 17083);
    injection.register(HiveMock());
    final manager = TestDataManager(injection.locator);
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
    var repo = injection.locator<Repository<City>>();
    var cities = await repo.findAll(params: {
      'page': {'offset': 1}
    });
    expect(cities.first.isNew, false);
    expect(cities.first.name, 'Munich');
    expect(cities.length, 3);

    var citiesFromLocal = await repo.findAll(remote: false);
    expect(citiesFromLocal.first.isNew, false);
  });

  test('findOne with include', () async {
    final repo = injection.locator<Repository<Company>>();
    final company = await repo.findOne('1', params: {'include': 'models'});
    expect(company.models.last.name, 'Model 3');
  });

  test('watchOne', () async {
    final modelRepo = injection.locator<Repository<Model>>();
    // make sure there are no items in local storage from previous tests
    // await repo.box.clear();
    // await repo.manager.metaBox.clear();
    final notifier = modelRepo.watchOne('1');

    dispose = notifier.addListener(
      expectAsync1((state) {
        final model = Model(id: '1', name: 'Roadster', company: BelongsTo());
        expect(state.model.name, equals(model.name));
      }),
      fireImmediately: false,
    );
  });

  test('save', () async {
    var repo = injection.locator<Repository<Model>>();
    var companies = await injection.locator<Repository<Company>>().findAll();
    var c = companies.last;
    var m = await Model(id: '3', name: 'Elon X', company: c.asBelongsTo)
        .init(repo)
        .save();
    var m2 = await repo.findOne('3');
    expect(m.id, m2.id);
    expect(m2.name, 'Elon X');
    // following assertions won't pass as server data
    // "loses" information (returns 0 relationships)
    // expect(m, m2);
    // expect(m2.company.value, c);
  });

  test('save without id', () async {
    var repo = injection.locator<Repository<Company>>();
    var company = Company(name: 'New Co', models: HasMany()).init(repo);

    var c2 = await company.save();
    expect(c2.id, isNotNull);
    expect(keyFor(company), keyFor(c2));

    var c3 = await repo.findOne(c2.id);
    expect(c2.name, company.name);
    expect(c3.name, c2.name);
    expect(keyFor(c2), keyFor(c3));
  });

  test('fetch with error', () async {
    expect(() async {
      await injection.locator<Repository<Company>>().findOne('2332');
    }, throwsA(isA<DataException>()));
  });

  tearDownAll(() async {
    await server.close();
    await injection.locator<Repository<Model>>().dispose();
    injection.clear();
  });
}
