import 'dart:async';
import 'dart:io';

import 'package:json_api/server.dart';
import 'package:json_api/src/server/server_document_factory.dart';
import 'package:json_api/url_design.dart';
import 'package:pedantic/pedantic.dart';

import 'controller.dart';
import 'dao.dart';
import 'model.dart';

Future<HttpServer> createServer(InternetAddress addr, int port) async {
  final models = ModelDAO();
  [
    Model('1')..name = 'Roadster',
    Model('2')..name = 'Model S',
    Model('3')..name = 'Model X',
    Model('4')..name = 'Model 3',
    Model('5')..name = 'X1',
    Model('6')..name = 'X3',
    Model('7')..name = 'X5',
  ].forEach(models.insert);

  final cities = CityDAO();
  [
    City('1')..name = 'Munich',
    City('2')..name = 'Palo Alto',
    City('3')..name = 'Ingolstadt',
  ].forEach(cities.insert);

  final companies = CompanyDAO();
  [
    Company('1')
      ..name = 'Tesla'
      ..headquarters = '2'
      ..models.addAll(['1', '2', '3', '4']),
    Company('2')
      ..name = 'BMW'
      ..headquarters = '1',
    Company('3')..name = 'Audi',
    Company('4')..name = 'Toyota',
  ].forEach(companies.insert);

  final pagination = FixedSizePage(20);

  final controller = CarsController({
    'companies': companies,
    'cities': cities,
    'models': models,
    'jobs': JobDAO()
  }, pagination);

  final httpServer = await HttpServer.bind(addr, port);
  final urlDesign = PathBasedUrlDesign(Uri.parse('http://localhost:$port'));
  final jsonApiServer = JsonApiServer(urlDesign, controller,
      documentFactory: ServerDocumentFactory(urlDesign));

  unawaited(httpServer.forEach(jsonApiServer.serve));
  return httpServer;
}
