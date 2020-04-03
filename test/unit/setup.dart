import 'package:hive/hive.dart';
import 'package:flutter_data/flutter_data.dart';
import 'package:mockito/mockito.dart';

import 'models/family.dart';
import 'models/house.dart';
import 'models/person.dart';

class HiveMock extends Mock implements HiveInterface {}

class FakeBox<T> extends Fake implements Box<T> {
  var _map = <String, T>{};
  @override
  T get(key, {T defaultValue}) {
    return _map[key] ?? defaultValue;
  }

  @override
  Future<void> put(key, T value) async {
    _map[key.toString()] = value;
  }

  @override
  Map<String, T> toMap() => _map;

  @override
  Iterable<String> get keys => _map.keys;

  @override
  Iterable<T> get values => _map.values;

  @override
  Future<void> close() => Future.value();
}

class FakeDataManager extends Fake implements DataManager {
  FakeDataManager(this.locator);
  final Locator locator;
  final Box<String> keysBox = FakeBox<String>();
  final autoModelInit = false;
}

final injection = DataServiceLocator();

final Function() setUpAllFn = () {
  injection.register(HiveMock());
  final manager = FakeDataManager(injection.locator);
  injection.register<DataManager>(manager);

  final houseLocalAdapter = $HouseLocalAdapter(FakeBox<House>(), manager);
  final familyLocalAdapter = $FamilyLocalAdapter(FakeBox<Family>(), manager);
  final personLocalAdapter = $PersonLocalAdapter(FakeBox<Person>(), manager);

  injection.register<LocalAdapter<House>>(houseLocalAdapter);
  injection.register<LocalAdapter<Family>>(familyLocalAdapter);
  injection.register<LocalAdapter<Person>>(personLocalAdapter);

  injection.register<Repository<House>>($HouseRepository(houseLocalAdapter));
  injection.register<Repository<Family>>($FamilyRepository(familyLocalAdapter));
  injection.register<Repository<Person>>($PersonRepository(personLocalAdapter));
};

final Function() tearDownAllFn = () async {
  await injection.locator<Repository<House>>().dispose();
  await injection.locator<Repository<Family>>().dispose();
  await injection.locator<Repository<Person>>().dispose();
  injection.clear();
};

////

// final mockHttpClient = MockClient((request) async {
//   final kBase = 'http://127.0.0.1:8080';
//   if (request.url.toString() == '$kBase/animals') {
//     return http.Response(
//         json
//             .encode(docFactory.makeCollectionDocument(request.url, []).toJson())
//             .toString(),
//         200);
//   }
//   return http.Response('server error', 500);
// });

// mixin TestMixin<T extends DataSupport<T>> on RemoteAdapter<T> {
//   // @override
//   // get baseUrl => 'http://localhost/';

//   http.Client _mockClient = mockHttpClient;

//   @override
//   Future<R> withHttpClient<R>(onRequest) => onRequest(_mockClient);
// }

// class FamilyTestRepository = $FamilyRepository with TestMixin;
// class HouseTestRepository = $HouseRepository with TestMixin;
// class PersonTestRepository = $PersonRepository with TestMixin;
