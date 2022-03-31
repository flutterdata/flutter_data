import 'package:flutter_data/flutter_data.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../_support/book.dart';
import '../../_support/family.dart';
import '../../_support/house.dart';
import '../../_support/node.dart';
import '../../_support/person.dart';
import '../../_support/pet.dart';
import '../../_support/setup.dart';
import '../../mocks.dart';

void main() async {
  setUp(setUpFn);
  tearDown(tearDownFn);

  test('scenario #1', () {
    // house does not yet exist
    final residenceKey = graph.getKeyForId('houses', '1',
        keyIfAbsent: DataHelpers.generateKey<House>());

    // since we're passing a key (not an ID)
    // we MUST use the local adapter serializer
    final f1 = familyRemoteAdapter.localAdapter.deserialize({
      'id': '1',
      'surname': 'Rose',
      'residence': residenceKey
    }).init(container.read);
    expect(f1.residence!.value, isNull);
    expect(keyFor(f1), isNotNull);

    // once it does
    final house = House(id: '1', address: '123 Main St').init(container.read);
    // it's automatically wired up
    expect(f1.residence!.value, house);
    expect(f1.residence!.value!.owner.value, f1);
    expect(house.owner.value, f1);

    // residence is omitted, but persons is included (no people exist yet)
    final personKey =
        graph.getKeyForId('people', '1', keyIfAbsent: 'people#a1a1a1');
    final f1b = familyRemoteAdapter.localAdapter.deserialize({
      'id': '1',
      'surname': 'Rose',
      'persons': [personKey],
    }).init(container.read);
    // therefore
    // residence remains wired
    expect(f1b.residence!.value, house);
    // persons is empty since no people exist yet (despite having keys)
    expect(f1b.persons, isEmpty);

    // once p1 exists
    final p1 = Person(id: '1', name: 'Axl', age: 58).init(container.read);
    // it's automatically wired up
    expect(f1b.persons.toSet(), {p1});

    // relationships are omitted - so they remain unchanged
    final f1c = familyRemoteAdapter.localAdapter
        .deserialize({'id': '1', 'surname': 'Rose'}).init(container.read);
    expect(f1c.persons.toSet(), {p1});
    expect(f1c.residence!.value, isNotNull);

    final p2 = Person(id: '2', name: 'Brian', age: 55).init(container.read);

    // persons has changed from [1] to [2]
    final f1d = familyRemoteAdapter.localAdapter.deserialize({
      'id': '1',
      'surname': 'Rose',
      'persons': [keyFor(p2)]
    }).init(container.read);
    // persons should be exactly equal to p2 (Brian)
    expect(f1d.persons.toSet(), {p2});
    // without directly modifying p2, its family should be automatically updated
    expect(p2.family.value, f1d);
    // and by the same token, p1's family should now be null
    expect(p1.family.value, isNull);

    // relationships are explicitly set to null
    final f1e = familyRemoteAdapter.localAdapter.deserialize({
      'id': '1',
      'surname': 'Rose',
      'persons': null,
      'residence': null
    }).init(container.read);
    expect(f1e.persons, isEmpty);
    expect(f1e.residence!.value, isNull);

    expect(keyFor(f1), equals(keyFor(f1e)));
  });

  test('scenario #1b (inverse)', () {
    // deserialize house, owner does not exist
    // since we're passing a key (not an ID)
    // we MUST use the local adapter serializer
    final h1 = houseRemoteAdapter.localAdapter.deserialize({
      'id': '1',
      'address': '123 Main St',
      'owner': 'families#a1a1a1'
    }).init(container.read);
    expect(h1.owner.value, isNull);
    expect(keyFor(h1), isNotNull);

    graph.getKeyForId('family', '1', keyIfAbsent: 'families#a1a1a1');

    // once it does
    final family = Family(id: '1', surname: 'Rose', residence: BelongsTo())
        .init(container.read);
    // it's automatically wired up & inverses work correctly
    expect(h1.owner.value, family);
    expect(h1.owner.value!.residence!.value, h1);
  });

  test('scenario #2', () {
    // (1) first load family (with relationships)
    final family = Family(
      id: '1',
      surname: 'Jones',
      persons: HasMany.fromJson({
        '_': [
          ['people#c1c1c1', 'people#c2c2c2', 'people#c3c3c3'],
          false,
          familyRepository
        ]
      }),
      residence: BelongsTo.fromJson({
        '_': ['houses#c98d1b', false, familyRepository]
      }),
    ).init(container.read);

    expect(family.residence!.key, isNotNull);
    expect(family.persons.keys.length, 3);

    // associate ids with keys
    graph.getKeyForId('people', '1', keyIfAbsent: 'people#c1c1c1');
    graph.getKeyForId('people', '2', keyIfAbsent: 'people#c2c2c2');
    graph.getKeyForId('people', '3', keyIfAbsent: 'people#c3c3c3');
    graph.getKeyForId('houses', '98', keyIfAbsent: 'houses#c98d1b');

    // test ids
    expect(family.persons.ids, {'1', '2', '3'});

    // (2) then load persons

    Person(id: '1', name: 'z1', age: 23).init(container.read);
    Person(id: '2', name: 'z2', age: 33).init(container.read);

    // (3) assert two first are linked, third one null, residence is null
    expect(family.persons.length, 2);
    expect(family.residence!.value, isNull);

    // (4) load the last person and assert it exists now
    final p3 = Person(id: '3', name: 'z3', age: 3).init(container.read);
    expect(p3.family.value, family);

    // (5) load family and assert it exists now
    final house =
        House(id: '98', address: '21 Coconut Trail').init(container.read);
    expect(house.owner.value, family);
    expect(family.residence!.value!.address, endsWith('Trail'));
    expect(house.owner.value, family); // same, passes here again
  });

  test('scenario #3', () {
    final igor = Person(name: 'Igor', age: 33).init(container.read);
    final f1 = Family(surname: 'Kamchatka', persons: {igor}.asHasMany)
        .init(container.read);
    expect(f1.persons.first.family.value, f1);

    final igor1b =
        Person(name: 'Igor', age: 33, family: BelongsTo()).init(container.read);

    final f1b = Family(surname: 'Kamchatka', persons: {igor1b}.asHasMany)
        .init(container.read);
    expect(f1b.persons.first.family.value!.surname, 'Kamchatka');

    final f2 =
        Family(surname: 'Kamchatka', persons: HasMany()).init(container.read);
    final igor2 =
        Person(name: 'Igor', age: 33, family: BelongsTo()).init(container.read);
    f2.persons.add(igor2);
    expect(f2.persons.first.family.value!.surname, 'Kamchatka');

    f2.persons.remove(igor2);
    expect(f2.persons, isEmpty);

    final residence =
        House(address: 'Sakharova Prospekt, 19').init(container.read);
    final f3 = Family(surname: 'Kamchatka', residence: residence.asBelongsTo)
        .init(container.read);
    expect(f3.residence!.value!.owner.value!.surname, 'Kamchatka');
    f3.residence!.value = null;
    expect(f3.residence!.value, isNull);

    final f4 = Family(surname: 'Kamchatka', residence: BelongsTo())
        .init(container.read);
    f4.residence!.value =
        House(address: 'Sakharova Prospekt, 19').init(container.read);
    expect(f4.residence!.value!.owner.value!.surname, 'Kamchatka');
  });

  test('scenario #4: maintain relationship reference validity', () async {
    final brian = Person(name: 'Brian', age: 52).init(container.read);
    final family =
        Family(id: '229', surname: 'Rose', persons: {brian}.asHasMany)
            .init(container.read);
    expect(family.persons.length, 1);

    // new family comes in locally with no persons relationship info
    final family2 = Family(id: '229', surname: 'Rose', persons: HasMany())
        .init(container.read);
    // it should keep the relationships unaltered
    expect(family2.persons.length, 1);

    // new family comes in from API (simulate) with no persons relationship info
    final family3 =
        (familyRemoteAdapter.deserialize({'id': '229', 'surname': 'Rose'}))
            .model!
            .init(container.read);
    // it should keep the relationships unaltered
    expect(family3.persons.length, 1);

    // new family comes in from API (simulate) with empty persons relationship
    final family4 = (familyRemoteAdapter
            .deserialize({'id': '229', 'surname': 'Rose', 'persons': []}))
        .model!
        .init(container.read);
    // it should keep the relationships unaltered
    expect(family4.persons.length, 0);

    // since we're passing a key (not an ID)
    // we MUST use the local adapter serializer
    final family5 = familyRemoteAdapter.localAdapter.deserialize({
      'id': '229',
      'surname': 'Rose',
      'persons': ['people#231aaa']
    }).init(container.read);

    graph.getKeyForId('people', '231', keyIfAbsent: 'people#231aaa');
    final axl = Person(id: '231', name: 'Axl', age: 58).init(container.read);
    expect(family5.persons.toSet(), {axl});
  });

  test('scenario #5: one-way relationships', () {
    // relationships that don't have an inverse
    final jerry = Dog(name: 'Jerry');
    final zoe = Dog(name: 'Zoe');
    final f1 = Family(surname: 'Carlson', dogs: {jerry, zoe}.asHasMany)
        .init(container.read);
    expect(f1.dogs!.toSet(), {jerry, zoe});
  });

  test('self-ref with freezed', () {
    final parent =
        Node(name: 'parent', children: HasMany()).init(container.read);
    final child =
        Node(name: 'child', parent: parent.asBelongsTo, children: HasMany())
            .init(container.read);

    // since child has children defined, the rel is empty
    expect(child.children, isEmpty);
    // since parent does not have a parent defined, the rel is null
    expect(parent.parent, isNull);

    // child & parent are infinitely related!
    expect(child.parent!.value, parent);
    expect(child.parent!.value!.children!.first, child);
  });

  test('freezed bidirectional one-to-many', () async {
    final book =
        Book(id: 23, title: 'Tao Te Ching', originalAuthor: BelongsTo())
            .init(container.read);
    final author = BookAuthor(id: 15, name: 'Lao Tzu', books: HasMany({book}))
        .init(container.read);

    final listener = Listener<DataState<BookAuthor?>>();
    final notifier = bookAuthorRepository.remoteAdapter
        .watchOneNotifier(author, remote: false);

    dispose = notifier.addListener(listener, fireImmediately: true);

    verify(listener(DataState(author, isLoading: false))).called(1);
    verifyNoMoreInteractions(listener);

    // we can do this because `author` has an ID
    final author2 = author.copyWith(name: 'Steve-O').init(container.read);
    await author2.save(remote: false);

    await oneMs();

    verify(listener(DataState(author2, isLoading: false))).called(1);
    verifyNoMoreInteractions(listener);

    // FD can't possibly know the newly created HasMany's owner
    // without initializing it
    expect(
        author.books!.first.originalAuthor!.value,
        isNot(equals(
            BookAuthor(id: 15, name: 'Steve-O', books: HasMany({book})))));

    // now it does
    expect(
        author.books!.first.originalAuthor!.value,
        equals(BookAuthor(id: 15, name: 'Steve-O', books: HasMany({book}))
            .init(container.read)));

    Book(
      id: 24,
      title: 'Lord of the Rings',
      // create a different relationship object but
      // equal to `author.books!.first.originalAuthor`
      originalAuthor: BelongsTo(author.books!.first.originalAuthor!.value),
    ).init(container.read);

    final books = author.books!.toList();
    // expect these two distinct objects are equal
    expect(books.first.originalAuthor, books.last.originalAuthor);

    // expect a LateInitializationError when trying
    // to compare uninitialized relationships
    expect(() => HasMany<Book>() == HasMany<Book>(), throwsA(isA<Error>()));

    expect(books.first.originalAuthor.toString(), 'BelongsTo<BookAuthor>(15)');
    expect(author.books.toString(), 'HasMany<Book>(23, 24)');
    expect(author.books!.first.originalAuthor!.value.toString(),
        'BookAuthor(id: 15, name: Steve-O, books: HasMany<Book>(23, 24))');
  });

  test('HasMany iterable proxies', () {
    final rel = {
      Person(id: '1', name: 'Martin', age: 49),
      Person(id: '2', name: 'Julia', age: 23)
    }.asHasMany;

    expect(rel.isNotEmpty, isTrue);
    expect(rel.toSet(), isA<Set>());
    expect(rel.where((e) => e.age! > 40), hasLength(1));
    expect(rel.map((e) => e.age! - 10).toSet(), {39, 13});
  });
}
