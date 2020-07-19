import 'package:flutter_data/flutter_data.dart';
import 'package:test/test.dart';

import '../../../models/family.dart';
import '../../../models/person.dart';
import '../../setup.dart';

void main() async {
  setUp(setUpFn);

  test('HasMany is a Set', () {
    final anne = Person(name: 'Anne', age: 59).init(owner);
    final f1 = Family(surname: 'Mayer', persons: {anne}.asHasMany).init(owner);

    f1.persons.add(anne);
    f1.persons.add(anne);
    expect(f1.persons.length, 1);
    expect(f1.persons.lookup(anne), anne);

    final agnes = Person(name: 'Agnes', age: 29).init(owner);
    f1.persons.add(agnes);
    expect(f1.persons.length, 2);

    f1.persons.remove(anne);
    expect(f1.persons, {agnes});
    f1.persons.add(null);
    expect(f1.persons, {agnes});

    f1.persons.clear();
    expect(f1.persons.length, 0);
  });

  test('watch', () async {
    final family = Family(
      id: '1',
      surname: 'Smith',
      persons: HasMany<Person>(),
    ).init(owner);

    final p1 = Person(name: 'a', age: 1).init(owner);
    final p2 = Person(name: 'b', age: 2).init(owner);
    final notifier = family.persons.watch();

    var i = 0;
    final dispose = notifier.addListener(
      expectAsync1((persons) {
        if (i == 0) expect(persons, {p1});
        if (i == 1) expect(persons, {p1, p2});
        if (i == 2) expect(persons, {p1, p2});
        if (i == 3) expect(persons, {p2});
        if (i == 4) expect(persons, {p2, p1});
        i++;
      }, count: 5),
      fireImmediately: false,
    );

    await runAndWait(() => family.persons.add(p1));
    await runAndWait(() => family.persons.add(p2));
    await runAndWait(() => family.persons.add(p2));
    await runAndWait(() => family.persons.remove(p1));
    await runAndWait(() => family.persons.add(p1));

    dispose();
  });
}
