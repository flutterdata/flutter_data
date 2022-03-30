import 'package:flutter_data/flutter_data.dart';
import 'package:test/test.dart';

import '../_support/family.dart';
import '../_support/house.dart';
import '../_support/person.dart';
import '../_support/setup.dart';

void main() async {
  setUp(setUpFn);
  tearDown(tearDownFn);

  test('deserialize existing (with save)', () {
    final family = Family(surname: 'Moletto').init(container.read);

    // simulate "save"
    graph.getKeyForId('families', '1098', keyIfAbsent: keyFor(family));
    final family2 = familyRemoteAdapter.localAdapter
        .deserialize({'id': '1098', 'surname': 'Moletto'}).init(container.read);

    expect(family2, Family(id: '1098', surname: 'Moletto'));
    expect(
        (familyRemoteAdapter.localAdapter as HiveLocalAdapter<Family>)
            .box!
            .keys,
        [keyFor(family2)]);
  });

  test('deserialize many local for same remote ID', () {
    final family = Family(surname: 'Moletto').init(container.read);
    final family2 = Family(surname: 'Zandiver').init(container.read);

    // simulate "save" for family
    graph.getKeyForId('families', '1298', keyIfAbsent: keyFor(family));
    final family1b = familyRemoteAdapter.localAdapter.deserialize({
      'id': '1298',
      'surname': 'Helsinki',
    }).init(container.read);

    // simulate "save" for family2
    graph.getKeyForId('families', '1298', keyIfAbsent: keyFor(family2));
    final family2b = familyRemoteAdapter.localAdapter.deserialize({
      'id': '1298',
      'surname': 'Oslo',
    }).init(container.read);

    // since obj returned with same ID
    expect(keyFor(family1b), keyFor(family2b));
  });

  test('local serialize', () {
    final p1r = {Person(id: '1', name: 'Franco', age: 28)}.asHasMany;
    final h1r = House(id: '1', address: '123 Main St').asBelongsTo;

    final family =
        Family(id: '1', surname: 'Smith', residence: h1r, persons: p1r);

    final map = familyRemoteAdapter.localAdapter.serialize(family);
    expect(map, {
      'id': '1',
      'surname': 'Smith',
      'residence': h1r,
      'persons': p1r,
    });
  });

  test('local deserialize', () {
    final p1r = {Person(id: '1', name: 'Franco', age: 28)}.asHasMany;
    final h1r = House(id: '1', address: '123 Main St').asBelongsTo;

    final map = {
      'id': '1',
      'surname': 'Smith',
      'residence': h1r.key,
      'persons': p1r.keys,
    };

    final family = familyRemoteAdapter.localAdapter.deserialize(map);
    expect(
        family,
        Family(
          id: '1',
          surname: 'Smith',
          residence: h1r,
          persons: p1r,
        ));
  });

  test('local deserialize with relationships', () {
    final house = House(id: '1', address: '123 Main St').init(container.read);
    final person = Person(id: '1', name: 'John', age: 21).init(container.read);

    final obj = {
      'id': '1',
      'surname': 'Smith',
      'residence': keyFor(house),
      'persons': [keyFor(person)]
    };

    final family =
        familyRemoteAdapter.localAdapter.deserialize(obj).init(container.read);

    expect(family, Family(id: '1', surname: 'Smith'));
    expect(family.residence!.value!.address, '123 Main St');
    expect(family.persons.first.age, 21);
  });

  test('hive adapter typeId', () {
    final a1 = familyRemoteAdapter.localAdapter as HiveLocalAdapter<Family>;
    final a1b = familyRemoteAdapter.localAdapter as HiveLocalAdapter<Family>;
    final a2 = houseRemoteAdapter.localAdapter as HiveLocalAdapter<House>;
    final a3 = personRemoteAdapter.localAdapter as HiveLocalAdapter<Person>;
    expect(<HiveLocalAdapter<DataModel>>[a1, a1b, a2, a3].map((a) => a.typeId),
        unorderedEquals([1, 1, 2, 3]));
  });
}
