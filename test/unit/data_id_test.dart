import 'package:flutter_data/flutter_data.dart';
import 'package:test/test.dart';

import 'models/family.dart';
import 'models/person.dart';
import 'setup.dart';

void main() async {
  test('no id', () {
    final manager = FakeDataManager(null);
    expect(DataId(null, manager).id, isNull);
  });

  test('produces a new key', () {
    final manager = FakeDataManager(null);
    var dataId = DataId<Person>('1', manager);
    expect(dataId.key, startsWith('people#'));
  });

  test('reuses a provided key', () {
    final manager = FakeDataManager(null);
    var dataId = DataId<Person>('29', manager, key: 'people#78a92b');
    expect(dataId.key, 'people#78a92b');
    expect(dataId.id, '29');
  });

  test('model is set only if manager is null', () {
    final manager = FakeDataManager(null);
    var dataId =
        DataId<Person>('1', null, model: Person(id: '1', name: "zzz", age: 7));
    expect(dataId.model, isNotNull);

    var dataId2 = DataId<Person>('2', manager,
        model: Person(id: '2', name: "zzz", age: 7));
    expect(dataId2.model, isNull);
  });

  test('reuses a key', () {
    final manager = FakeDataManager(null);
    var dataId = DataId<Person>('1', manager, key: 'people#a5a5a5');
    expect(dataId.key, 'people#a5a5a5');
  });

  // static utils

  test('getType', () {
    expect(DataId.getType<Person>(), 'people');
    expect(DataId.getType('Family'), 'families');
  });

  test('byKeys', () {
    final manager = FakeDataManager(null);
    // including ids that contain '#' (also used in internal format)
    manager.keysBox.put('people#p#1', 'people#a1a1a1');
    manager.keysBox.put('people#2', 'people#b2b2b2');
    manager.keysBox.put('people#3', 'people#c3c3c3');

    var list = DataId.byKeys<Person>(
        ['people#a1a1a1', 'people#b2b2b2', 'people#c3c3c3'], manager);
    expect(list, [
      DataId<Person>('p#1', manager),
      DataId<Person>('2', manager),
      DataId<Person>('3', manager)
    ]);
  });

  test('byKey', () {
    final manager = FakeDataManager(null);
    manager.keysBox.put('families#3', 'families#c3c3c3');

    var dataId = DataId.byKey<Family>('families#c3c3c3', manager);
    expect(dataId, DataId<Family>('3', manager));
    expect(dataId, isNot(DataId<Person>('3', manager)));
  });

  test('equals', () {
    final manager = FakeDataManager(null);
    expect(DataId<Person>("1", manager), DataId<Person>("1", manager));
  });

  test('not equals', () {
    final manager = FakeDataManager(null);
    expect(DataId<Person>("1", manager), isNot(DataId<Family>("1", manager)));
  });
}
