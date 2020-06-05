import 'dart:io';

import 'package:json_api/document.dart';
import 'package:json_api/server.dart';
import 'package:pedantic/pedantic.dart';
import 'package:uuid/uuid.dart';

Future<HttpServer> createServer(InternetAddress addr, int port) async {
  final schema = {
    'models': {
      '1': Resource('models', '1', attributes: {'name': 'Roadster'}),
      '2': Resource('models', '2', attributes: {'name': 'Model S'}),
      '3': Resource('models', '3', attributes: {'name': 'Model X'}),
      '4': Resource('models', '4', attributes: {'name': 'Model 3'}),
      '5': Resource('models', '5', attributes: {'name': 'X1'}),
      '6': Resource('models', '6', attributes: {'name': 'X3'}),
      '7': Resource('models', '7', attributes: {'name': 'X5'}),
    },
    'cities': {
      '1': Resource('cities', '1', attributes: {'name': 'Munich'}),
      '2': Resource('cities', '2', attributes: {'name': 'Palo Alto'}),
      '3': Resource('cities', '3', attributes: {'name': 'Ingolstadt'}),
    },
    'companies': {
      '1': Resource(
        'companies',
        '1',
        attributes: {'name': 'Tesla'},
        toOne: {
          'headquarters': Identifier('cities', '2'),
        },
        toMany: {
          'models': [
            Identifier('models', '1'),
            Identifier('models', '2'),
            Identifier('models', '3'),
            Identifier('models', '4'),
          ],
        },
      ),
      '2': Resource(
        'companies',
        '2',
        attributes: {'name': 'BMW'},
        toOne: {
          'headquarters': Identifier('cities', '1'),
        },
      ),
      '3': Resource('companies', '3', attributes: {'name': 'Audi'}),
      '4': Resource('companies', '4', attributes: {'name': 'Toyota'}),
    },
  };
  final repo = InMemoryRepository(schema, nextId: Uuid().v4);
  final controller = RepositoryController(repo);
  final jsonApiServer = JsonApiServer(controller);
  final dartServer = DartServer(jsonApiServer);
  final httpServer = await HttpServer.bind(addr, port);
  unawaited(httpServer.forEach(dartServer));
  return httpServer;
}
