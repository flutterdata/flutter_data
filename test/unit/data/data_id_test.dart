import 'package:flutter_data/flutter_data.dart';
import 'package:test/test.dart';

import '../../models/person.dart';
import '../setup.dart';

void main() async {
  test('produces a new key', () {
    final manager = TestDataManager(null);
    final key = manager.getKey('1');
    expect(key, startsWith('people#'));
  });

  test('reuses a provided key', () {
    final manager = TestDataManager(null);
    final key = manager.getKey('29', keyIfAbsent: 'people#78a92b');
    expect(key, 'people#78a92b');
    expect(manager.getId(key), '29');
  });

  test('reuses a key', () {
    final manager = TestDataManager(null);
    final key = manager.getKey('1', keyIfAbsent: 'people#a5a5a5');
    expect(key, 'people#a5a5a5');
  });

  // static utils

  test('getType', () {
    expect(Repository.getType<Person>(), 'people');
    expect(Repository.getType('Family'), 'families');
    // `type` argument takes precedence
    // TODO RESTORE
    // expect(DataId<Family>('28', null, type: 'animals').type, 'animals');
  });

  test('byKeys', () {
    final manager = TestDataManager(null);

    // including ids that contain '#' (also used in internal format)
    manager.getKey('people#p#1', keyIfAbsent: 'people#a1a1a1');
    manager.getKey('people#2', keyIfAbsent: 'people#b2b2b2');
    manager.getKey('people#3', keyIfAbsent: 'people#c3c3c3');

    final keys =
        ['people#a1a1a1', 'people#b2b2b2', 'people#c3c3c3'].map(manager.getKey);
    expect(keys, ['p#1', '2', '3']);
  });

  test('byKey', () {
    final manager = TestDataManager(null);
    manager.getKey('families#3', keyIfAbsent: 'families#c3c3c3');

    final key = 'families#c3c3c3';
    expect(key, manager.getKey('3'));
    expect(key, isNot(manager.getKey('3')));
  });

  test('two models with id should get the same key', () {
    final manager = TestDataManager(null);
    expect(manager.getKey('2812'), manager.getKey('2812'));
  });

  test('should prioritize ID', () {
    final manager = TestDataManager(null);
    final key = manager.getKey('772');

    final key2 = manager.getKey(null);

    // we are telling manager to reuse the existing key
    // BUT a key for id=772 already exists, so that one will precede
    final key3 = manager.getKey('772', keyIfAbsent: key2);

    expect(key2, isNot(key3));
    expect(key, key3);
  });
}
