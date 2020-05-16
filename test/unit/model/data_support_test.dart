import 'package:flutter_data/flutter_data.dart';
import 'package:test/test.dart';

import '../../models/family.dart';
import '../../models/person.dart';
import '../../models/pet.dart';
import '../setup.dart';

void main() async {
  setUpAll(setUpAllFn);
  tearDownAll(tearDownAllFn);

  test('throws if not initialized', () {
    expect(() {
      return Family(surname: 'Willis').save();
    }, throwsA(isA<AssertionError>()));
  });

  test('init', () async {
    var repo = injection.locator<Repository<Person>>();

    var family = Family(id: '55', surname: 'Kelley');
    var model =
        Person(id: '1', name: 'John', age: 27, family: family.asBelongsTo)
            .init(repo);

    // (1) it wires up the relationship (setOwnerInRelationship)
    expect(model.family.key, repo.manager.dataId<Family>('55').key);

    // (2) it saves the model locally
    expect(model, await repo.findOne(model.id));
  });

  // misc compatibility tests

  test('should reuse key', () {
    var manager = injection.locator<DataManager>();
    var repository = injection.locator<Repository<Person>>();

    // id-less person
    var p1 = Person(name: 'Frank', age: 20).init(repository);
    expect(repository.box.keys, contains(p1.key));

    // person with new id, reusing existing key
    manager.dataId<Person>('221', useKey: p1.key);
    var p2 = Person(id: '221', name: 'Frank2', age: 32).init(repository);
    expect(p1.key, p2.key);

    expect(repository.box.keys, contains(p2.key));
  });

  test('should resolve to the same key', () {
    var dogRepo = injection.locator<Repository<Dog>>();
    var dog = Dog(id: '2', name: 'Walker').init(dogRepo);
    var dog2 = Dog(id: '2', name: 'Walker').init(dogRepo);
    expect(dog.key, dog2.key);
  });

  test('should work with subclasses', () {
    var familyRepo = injection.locator<Repository<Family>>();
    var dogRepo = injection.locator<Repository<Dog>>();
    var dog = Dog(id: '2', name: 'Walker').init(dogRepo);

    var f = Family(surname: 'Walker', dogs: {dog}.asHasMany).init(familyRepo);
    expect(f.dogs.first.name, 'Walker');
  });

  test('data exception equality', () {
    expect(DataException(Exception('whatever'), 410),
        DataException(Exception('whatever'), 410));
    expect(DataException([Exception('whatever')], 410),
        isNot(DataException(Exception('whatever'), 410)));
  });
}

// mutable id tests

// test('should remove "mutable" stray zebras', () async {
//   var manager = injection.locator<DataManager>();
//   var repository = injection.locator<Repository<Zebra>>();

//   // a reference for zebra id=772 has been created
//   var dataId = manager.dataId<Zebra>('772');

//   var taco = Zebra(id: null, name: 'Taco').init(repository);
//   // key(id=772) will be different to key(id=null)
//   expect(taco.key, isNot(dataId.key));
//   // zebra was saved with id=null
//   expect((await repository.findAll()).length, 1);

//   // if we assign an id=772 and re-initialize
//   taco.id = '772';
//   taco.init(repository);

//   // the original key (key(id=772)) will be found
//   expect(taco.key, dataId.key);
//   // and the stray zebra (id=null) will be removed
//   // so we only keep the record for id=772
//   expect((await repository.findAll()).length, 1);
//   expect(repository.localAdapter.findOne(taco.key), isNotNull);
// });

// test('re-save with mutable id', () async {
//   var repository = injection.locator<Repository<Zebra>>();
//   await repository.localAdapter.clear();
//   var z = Zebra(id: '779', name: 'Mercy').init(repository);
//   print(z.key);

//   // mimics what repository.deserialize() does internally
//   // deserialize with init (DataSupport) and immediately assign id
//   var _z = repository.localAdapter
//       .deserialize({'name': "Patsy"}).init(repository)
//         ..id = '779';
//   // then initialize again (z.key will be NEW, assigned to id=null)
//   z = _z.init(repository, key: z.key, save: true);

//   expect(repository.localAdapter.keys, [z.key]);
// });

// @DataRepository([])
// @JsonSerializable()
// class Zebra with DataSupportMixin<Zebra> {
//   String id;
//   String name;

//   Zebra({this.id, this.name});
//   factory Zebra.fromJson(Map<String, dynamic> json) => _$ZebraFromJson(json);
//   Map<String, dynamic> toJson() => _$ZebraToJson(this);
// }
