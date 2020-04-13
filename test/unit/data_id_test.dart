import 'package:flutter_data/flutter_data.dart';
import 'package:test/test.dart';

import 'models/family.dart';
import 'models/person.dart';
import 'setup.dart';

void main() async {
  test('no id', () {
    final manager = TestDataManager(null);
    expect(DataId(null, manager).id, isNull);
  });

  test('produces a new key', () {
    final manager = TestDataManager(null);
    var dataId = manager.dataId<Person>('1');
    expect(dataId.key, startsWith('people#'));
  });

  test('reuses a provided key', () {
    final manager = TestDataManager(null);
    var dataId = manager.dataId<Person>('29', key: 'people#78a92b');
    expect(dataId.key, 'people#78a92b');
    expect(dataId.id, '29');
  });

  test('reuses a key', () {
    final manager = TestDataManager(null);
    var dataId = manager.dataId<Person>('1', key: 'people#a5a5a5');
    expect(dataId.key, 'people#a5a5a5');
  });

  // static utils

  test('getType', () {
    expect(DataId.getType<Person>(), 'people');
    expect(DataId.getType('Family'), 'families');
  });

  test('byKeys', () {
    final manager = TestDataManager(null);
    // including ids that contain '#' (also used in internal format)
    manager.keysBox.put('people#p#1', 'people#a1a1a1');
    manager.keysBox.put('people#2', 'people#b2b2b2');
    manager.keysBox.put('people#3', 'people#c3c3c3');

    var list = DataId.byKeys<Person>(
        ['people#a1a1a1', 'people#b2b2b2', 'people#c3c3c3'], manager);
    expect(list, [
      manager.dataId<Person>('p#1'),
      manager.dataId<Person>('2'),
      manager.dataId<Person>('3')
    ]);
  });

  test('byKey', () {
    final manager = TestDataManager(null);
    manager.keysBox.put('families#3', 'families#c3c3c3');

    var dataId = DataId.byKey<Family>('families#c3c3c3', manager);
    expect(dataId, manager.dataId<Family>('3'));
    expect(dataId, isNot(manager.dataId<Person>('3')));
  });

  test('equals', () {
    final manager = TestDataManager(null);
    expect(manager.dataId<Person>("1"), manager.dataId<Person>("1"));
  });

  test('not equals', () {
    final manager = TestDataManager(null);
    expect(manager.dataId<Person>("1"), isNot(manager.dataId<Family>("1")));
  });

  test('two models without id should get different keys', () {
    final manager = TestDataManager(null);
    expect(manager.dataId<Person>(null), isNot(manager.dataId<Person>(null)));
  });

  test('two models with id should get the same key', () {
    final manager = TestDataManager(null);
    expect(manager.dataId<Person>('2812'), manager.dataId<Person>('2812'));
  });

  test('should prioritize ID', () {
    final manager = TestDataManager(null);
    var dataId = manager.dataId<Person>('772');

    var dataId2 = manager.dataId<Person>(null);
    // we are telling DataId to reuse the existing key
    // BUT a key for id=772 already exists, so that one will precede
    var dataId3 = manager.dataId<Person>('772', key: dataId2.key);

    expect(dataId2, isNot(dataId3));
    expect(dataId, dataId3);
  });
}
