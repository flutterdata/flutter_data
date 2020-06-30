import 'package:flutter_data/flutter_data.dart';
import 'package:test/test.dart';

import '../../../models/family.dart';
import '../../../models/house.dart';
import '../../../models/person.dart';
import '../../setup.dart';

void main() async {
  setUpAll(setUpAllFn);
  tearDownAll(tearDownAllFn);

  test('set owner in relationships', () {
    final person =
        Person(id: '1', name: 'John', age: 37).init(manager: manager);
    final house =
        House(id: '31', address: '123 Main St').init(manager: manager);
    final house2 =
        House(id: '2', address: '456 Main St').init(manager: manager);

    final family = Family(
        id: '1',
        surname: 'Smith',
        residence: BelongsTo<House>(house),
        persons: HasMany<Person>({person}));

    // no dataId associated to family or relationships
    expect(family.residence.key, isNull);
    expect(family.persons.keys, isEmpty);

    family.init(manager: manager);

    // relationships are now associated to a key
    expect(family.residence.key, manager.getKeyForId('houses', '31'));
    expect(family.persons.keys.first, manager.getKeyForId('people', '1'));

    // ensure there are not more than 1 key
    family.residence.value = house2;
    expect(family.residence.keys, hasLength(1));
  });

  test('watch', () async {
    final family = Family(
      id: '22',
      surname: 'Besson',
      residence: BelongsTo<House>(),
    ).init(manager: manager);

    final notifier = family.residence.watch();

    var i = 0;
    notifier.addListener(
      expectAsync1((house) {
        if (i == 0) expect(house.address, startsWith('456'));
        if (i == 1) expect(house.address, startsWith('123'));
        if (i == 2) expect(house, isNull);
        i++;
      }, count: 3),
      fireImmediately: false,
    );

    await runAndWait(() => family.residence.value =
        House(id: '2', address: '456 Main St').init(manager: manager));
    await runAndWait(() => family.residence.value =
        House(id: '1', address: '123 Main St').init(manager: manager));
    await runAndWait(() => family.residence.value = null);
  });
}
