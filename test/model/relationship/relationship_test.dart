import 'package:flutter_data/flutter_data.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../_support/book.dart';
import '../../_support/familia.dart';
import '../../_support/house.dart';
import '../../_support/node.dart';
import '../../_support/person.dart';
import '../../_support/pet.dart';
import '../../_support/setup.dart';

void main() async {
  setUp(setUpFn);
  tearDown(tearDownFn);

  test('scenario #1', () {
    final adapter = container.familia;

    final f1 = adapter.deserialize({'id': '1', 'surname': 'Rose'}).saveLocal();
    expect(f1.residence.value, isNull);
    expect(keyFor(f1), isNotNull);

    // once it does
    final house = House(id: '1', address: '123 Main St', owner: f1.asBelongsTo)
        .saveLocal();
    expect(f1.residence.value, house);
    expect(f1.residence.value!.owner.value, f1);
    expect(house.owner.value, f1);

    final f1b = adapter.deserialize({
      'id': '1',
      'surname': 'Rose',
    }).saveLocal();

    // residence should remain wired
    expect(f1b.residence.value, house);
    // persons is empty since no people exist yet (despite having keys)
    expect(f1b.persons, isEmpty);

    final p1 = Person(id: '1', name: 'Axl', age: 58, familia: f1b.asBelongsTo)
        .saveLocal();
    expect(f1b.persons, isNotEmpty);

    // relationships are omitted - so they remain unchanged
    final f1c = adapter.deserialize({'id': '1', 'surname': 'Rose'}).saveLocal();
    expect(f1c.persons.toSet(), {p1});
    expect(f1c.residence.value, isNotNull);

    final p2 = Person(id: '2', name: 'Brian', age: 55).saveLocal();

    // persons has changed from [1] to [2]
    final f1d = adapter.deserialize({
      'id': '1',
      'surname': 'Rose',
      'persons': [keyFor(p2)]
    }).saveLocal();
    // persons should be exactly equal to p2 (Brian)
    expect(f1d.persons.toSet(), {p2});
    // without directly modifying p2, its familia should be automatically updated
    expect(p2.familia.value, f1d);
    // and by the same token, p1's familia should now be null
    expect(p1.familia.value, isNull);

    // relationships are explicitly set to null
    final f1e = adapter.deserialize({
      'id': '1',
      'surname': 'Rose',
      'persons': null,
      'residence': null
    }).saveLocal();
    expect(f1e.persons, isEmpty);
    expect(f1e.residence.value, isNull);

    expect(keyFor(f1), equals(keyFor(f1e)));
  });

  test('scenario #1b (inverse)', () {
    final adapter = container.houses;
    // deserialize house, owner does not exist
    // since we're passing a key (not an ID)
    // we sync-deserialize
    final h1 = adapter.deserialize({
      'id': '1',
      'address': '123 Main St',
      'owner':
          'familia#2' // `2` because it is the second insertion in this test
    }).saveLocal();
    expect(h1.owner.value, isNull);
    expect(keyFor(h1), isNotNull);

    // once it does
    final familia =
        Familia(id: '1', surname: 'Rose', residence: BelongsTo()).saveLocal();
    // it's automatically wired up & inverses work correctly
    expect(h1.owner.value, familia);
    expect(h1.owner.value!.residence.value, h1);
  });

  test('scenario #2', () {
    // (1) first load familia (with relationships)
    final familia = Familia(
      id: '1',
      surname: 'Jones',
      persons: HasMany.fromJson({
        '_': {'people#2', 'people#3', 'people#4'}
      }),
      residence: BelongsTo.fromJson({
        '_': {'houses#5'}
      }),
    ).saveLocal();

    expect(familia.residence.key, isNotNull);
    expect(familia.residence.value, isNull);
    expect(familia.persons.keys.length, 3);

    // no people have been loaded
    expect(familia.persons.toList(), isEmpty);

    // (2) then load people
    final p1 = Person(id: '1', name: 'z1', age: 23).saveLocal();
    final p2 = Person(id: '2', name: 'z2', age: 33).saveLocal();

    // (3) assert two first are linked, third one null, residence is null
    expect(familia.persons.toList(), {p1, p2});
    expect(familia.residence.value, isNull);

    // (4) load the last person and assert it exists now
    final p3 = Person(id: '3', name: 'z3', age: 3).saveLocal();
    expect(p3.familia.value, familia);

    // (5) load house and assert it exists now
    final house = House(id: '98', address: '21 Coconut Trail').saveLocal();
    expect(house.owner.value, familia);
    expect(familia.residence.value!.address, endsWith('Trail'));
    expect(house.owner.value, familia); // same, passes here again
  });

  test('scenario #3', () {
    final igor = Person(name: 'Igor', age: 33).saveLocal();
    final f1 =
        Familia(surname: 'Kamchatka', persons: {igor}.asHasMany).saveLocal();

    expect(f1.persons.first, equals(igor));
    expect(f1.persons.first.familia.value, f1);

    final igor1b =
        Person(name: 'Igor', age: 33, familia: BelongsTo()).saveLocal();

    final f1b =
        Familia(surname: 'Kamchatka', persons: {igor1b}.asHasMany).saveLocal();
    expect(f1b.persons.first.familia.value!.surname, 'Kamchatka');

    final f2 = Familia(surname: 'Kamchatka', persons: HasMany()).saveLocal();
    final igor2 =
        Person(name: 'Igor', age: 33, familia: BelongsTo()).saveLocal();
    f2.persons.add(igor2);
    expect(f2.persons.first.familia.value!.surname, 'Kamchatka');

    f2.persons.remove(igor2);
    expect(f2.persons, isEmpty);

    final residence = House(address: 'Sakharova Prospekt, 19').saveLocal();
    final f3 = Familia(surname: 'Kamchatka', residence: residence.asBelongsTo)
        .saveLocal();
    expect(f3.residence.value!.owner.value!.surname, 'Kamchatka');
    f3.residence.value = null;
    expect(f3.residence.value, isNull);

    final f4 =
        Familia(surname: 'Kamchatka', residence: BelongsTo()).saveLocal();
    f4.residence.value = House(address: 'Sakharova Prospekt, 19').saveLocal();
    f4.saveLocal();
    expect(f4.residence.value!.owner.value!.surname, 'Kamchatka');
  });

  test('scenario #4: maintain relationship reference validity', () async {
    final brian = Person(name: 'Brian', age: 52).saveLocal();
    final familia =
        Familia(id: '229', surname: 'Rose', persons: {brian}.asHasMany)
            .saveLocal();
    expect(familia.persons.toSet(), {brian});

    // new familia comes in locally with no persons relationship information
    final familia2 =
        Familia(id: '229', surname: 'Rose', persons: HasMany()).saveLocal();
    // it should keep the relationships unaltered
    expect(familia2.persons.toSet(), {brian});

    // new familia comes in from API (simulate) with no persons relationship information
    final familia3 = (await container.familia
            .deserializeAsync({'id': '229', 'surname': 'Rose'}))
        .model!;
    // it should keep the relationships unaltered
    expect(familia3.persons.toSet(), {brian});

    // new familia comes in from API (simulate) with empty persons relationship
    final familia4 = (await container.familia
            .deserializeAsync({'id': '229', 'surname': 'Rose', 'persons': []}))
        .model!
        .saveLocal();
    // it should keep the relationships unaltered
    expect(familia4.persons.isEmpty, isTrue);

    // since we're passing a key (not an ID)
    // we MUST use the local adapter serializer
    final familia5 = container.familia.deserialize({
      'id': '229',
      'surname': 'Rose',
      'persons': ['people#3']
    }).saveLocal();

    final axl = Person(id: '231', name: 'Axl', age: 58).saveLocal();
    expect(familia5.persons.toSet(), {axl});
  });

  test('scenario #5: one-way relationships', () {
    // relationships that don't have an inverse
    final jerry = Dog(name: 'Jerry').saveLocal();
    final zoe = Dog(name: 'Zoe').saveLocal();
    final f1 =
        Familia(surname: 'Carlson', dogs: {jerry, zoe}.asHasMany).saveLocal();
    expect(f1.dogs!.toSet(), {jerry, zoe});
  });

  test('self-ref with freezed', () {
    // nodes are auto-saved (via `onModelInit`)
    final parent = Node(name: 'parent', children: HasMany());
    final child =
        Node(name: 'child', parent: parent.asBelongsTo, children: HasMany());
    // final child2 =
    //     Node(name: 'child', parent: parent.asBelongsTo, children: HasMany());

    // since child has children defined, the rel is empty
    expect(child.children, isEmpty);
    expect(child.parent?.value, isNotNull);
    // since parent does not have a parent defined, the rel is null
    expect(parent.parent, isNull);

    // child & parent are infinitely related!
    expect(child.parent!.value!.name, parent.name);

    expect(child.parent!.value!.children!.first, equals(child));
  });

  test('freezed bidirectional one-to-many', () async {
    final book = Book(
            id: 23,
            title: 'Tao Te Ching',
            originalAuthor: BelongsTo(),
            house: BelongsTo(),
            ardentSupporters: HasMany())
        .saveLocal();
    final author =
        BookAuthor(id: 15, name: 'Lao Tzu', books: HasMany({book})).saveLocal();
    expect(author.books.first, book);

    final listener = Listener<DataState<BookAuthor?>>();
    final notifier = container.bookAuthors.watchOneNotifier(author);

    final dispose = notifier.addListener(listener);
    disposeFns.add(dispose);

    verify(listener(DataState(author, isLoading: false))).called(1);
    verifyNoMoreInteractions(listener);

    final author2 = author.copyWith(name: 'Steve-O').saveLocal();

    await oneMs();
    expect(author.books.first, book);
    verify(listener(DataState(author2, isLoading: false))).called(1);
    verifyNoMoreInteractions(listener);

    expect(author.books.first.originalAuthor!.value,
        equals(BookAuthor(id: 15, name: 'Steve-O', books: HasMany({book}))));

    Book(
      id: 24,
      title: 'Lord of the Rings',
      // create a different relationship object but
      // equal to `author.books!.first.originalAuthor`
      originalAuthor: BelongsTo(author.books.first.originalAuthor!.value),
      ardentSupporters: HasMany(),
    ).saveLocal();

    final books = author.books.toList();
    // expect these two distinct objects are equal
    expect(books.first.originalAuthor!.value, books.last.originalAuthor!.value);

    // expect(books.first.originalAuthor?.id, 15);
    expect(author.books.map((p) => p.id), unorderedEquals([23, 24]));
    expect(author.books.first.originalAuthor!.value!.books.map((p) => p.id),
        unorderedEquals([23, 24]));
  });

  test('HasMany iterable proxies', () {
    final fam = Familia(
            surname: 'Tito',
            persons: {
              Person(id: '1', name: 'Martin', age: 49).saveLocal(),
              Person(id: '2', name: 'Julia', age: 23).saveLocal()
            }.asHasMany)
        .saveLocal();

    expect(fam.persons.isPresent, isTrue);
    expect(fam.persons.toSet(), isA<Set>());
    expect(fam.persons.where((e) => e.age! > 40), hasLength(1));
    expect(fam.persons.map((e) => e.age! - 10).toSet(), {39, 13});
  });
}
