// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'person.dart';

// **************************************************************************
// RepositoryGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, duplicate_ignore

mixin $PersonLocalAdapter on LocalAdapter<Person> {
  static final Map<String, FieldMeta> _kPersonFieldMetas = {
    'age': AttributeMeta<Person>(
      name: 'age',
      type: 'int',
      nullable: true,
      internalType: 'int',
    ),
    'name': AttributeMeta<Person>(
      name: 'name',
      type: 'String',
      nullable: false,
      internalType: 'String',
    ),
    'familia': RelationshipMeta<Familia>(
      name: 'familia',
      inverseName: 'persons',
      type: 'familia',
      kind: 'BelongsTo',
      instance: (_) => (_ as Person).familia,
    )
  };

  @override
  Map<String, FieldMeta> get fieldMetas => _kPersonFieldMetas;

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
class $PersonIsarLocalAdapter = IsarLocalAdapter<Person>
    with $PersonLocalAdapter;

class $PersonRemoteAdapter = RemoteAdapter<Person>
    with
        PersonLoginAdapter,
        GenericDoesNothingAdapter<Person>,
        YetAnotherLoginAdapter;

final internalPeopleRemoteAdapterProvider = Provider<RemoteAdapter<Person>>(
    (ref) => $PersonRemoteAdapter(
        $PersonIsarLocalAdapter(ref.read), InternalHolder(_peopleFinders)));

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

extension PersonRelationshipGraphNodeX on RelationshipGraphNode<Person> {
  RelationshipGraphNode<Familia> get familia {
    final meta = $PersonLocalAdapter._kPersonFieldMetas['familia']
        as RelationshipMeta<Familia>;
    return meta.clone(
        parent: this is RelationshipMeta ? this as RelationshipMeta : null);
  }
}
