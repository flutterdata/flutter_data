// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'person.dart';

// **************************************************************************
// RepositoryGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, duplicate_ignore

mixin $PersonLocalAdapter on LocalAdapter<Person> {
  static final rdata = RelationshipData<Person>({
    'familia': RelationshipDataItem<Person>(
      name: 'familia',
      inverseName: 'persons',
      type: 'familia',
      kind: 'BelongsTo',
      instance: (_) => _.familia,
    )
  });

  @override
  RelationshipData<Person> get relationshipData => rdata;

  @override
  Person deserialize(map) {
    map = transformDeserialize(map);
    return Person.fromJson(map);
  }

  @override
  Map<String, dynamic> serialize(model, {bool withRelationships = true}) {
    final map = model.toJson();
    return transformSerialize(map, withRelationships: withRelationships);
  }
}

final _peopleFinders = <String, dynamic>{};

// ignore: must_be_immutable
class $PersonHiveLocalAdapter = HiveLocalAdapter<Person>
    with $PersonLocalAdapter;

class $PersonRemoteAdapter = RemoteAdapter<Person>
    with
        PersonLoginAdapter,
        GenericDoesNothingAdapter<Person>,
        YetAnotherLoginAdapter;

final internalPeopleRemoteAdapterProvider = Provider<RemoteAdapter<Person>>(
    (ref) => $PersonRemoteAdapter(
        $PersonHiveLocalAdapter(ref.read), InternalHolder(_peopleFinders)));

final peopleRepositoryProvider =
    Provider<Repository<Person>>((ref) => Repository<Person>(ref.read));

extension PersonDataRepositoryX on Repository<Person> {
  PersonLoginAdapter get personLoginAdapter =>
      remoteAdapter as PersonLoginAdapter;
  GenericDoesNothingAdapter<Person> get genericDoesNothingAdapter =>
      remoteAdapter as GenericDoesNothingAdapter<Person>;
  YetAnotherLoginAdapter get yetAnotherLoginAdapter =>
      remoteAdapter as YetAnotherLoginAdapter;
}

extension PersonRelationshipDataX on RelationshipData<Person> {
  RelationshipDataItem<Person> get familia => items['familia']!;
}
