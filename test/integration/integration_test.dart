import 'dart:io';

import 'package:flutter_data/flutter_data.dart';
import 'package:test/test.dart';

import '../unit/setup.dart';
import 'models.dart';
import 'server/main.dart';

final injection = DataServiceLocator();

void main() async {
  HttpServer server;
  setUpAll(() async {
    server = await createServer(InternetAddress.loopbackIPv4, 17083);
    injection.register(HiveMock());
    final manager = TestDataManager(injection.locator);
    injection.register<DataManager>(manager);

    final companyLocalAdapter =
        $CompanyLocalAdapter(FakeBox<Company>(), manager);
    final cityLocalAdapter = $CityLocalAdapter(FakeBox<City>(), manager);
    final modelLocalAdapter = $ModelLocalAdapter(FakeBox<Model>(), manager);

    // we use $CompanyRepository as it already has the TestMixin baked in
    injection
        .register<Repository<Company>>($CompanyRepository(companyLocalAdapter));
    injection.register<Repository<City>>(CityTestRepository(cityLocalAdapter));
    injection
        .register<Repository<Model>>(ModelTestRepository(modelLocalAdapter));
  });

  test('findAll', () async {
    var repo = injection.locator<Repository<City>>();
    var cities = await repo.findAll();
    expect(cities.first.name, "Munich");
    expect(cities.length, 3);
  });

  test('findOne with include', () async {
    var repo = injection.locator<Repository<Company>>();
    var company = await repo.findOne("1", params: {'include': 'models'});
    expect(company.models.last.name, "Model 3");
  });

  test('watchOne', () async {
    // var repo = injection.locator<Repository<Model>>();
    // var stream = repo.watchOne('1');
    // TODO implement watch() in FakeBox
    // await expectLater(stream, emitsInOrder([Model(id: '1', name: 'Roadster')]));
  });

  test('save', () async {
    var repo = injection.locator<Repository<Model>>();
    var companies = await injection.locator<Repository<Company>>().findAll();
    var c = companies.last;
    await Model(id: '3', name: 'Elon X', company: c.asBelongsTo)
        .init(repo)
        .save();
    var m2 = await repo.findOne('3');
    expect(m2.name, "Elon X");
    expect(m2.company.value, c);
  });

  test('save without id', () async {
    var repo = injection.locator<Repository<Company>>();
    var company =
        await Company(name: "New Co", models: HasMany()).init(repo).save();
    expect(company.id, isNotNull);
    var c2 = await repo.findOne(company.id);
    expect(c2, company);
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
