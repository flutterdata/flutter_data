// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'person.dart';

// **************************************************************************
// AdapterGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, duplicate_ignore

mixin _$PersonAdapter on Adapter<Person> {
  static final Map<String, RelationshipMeta> _kPersonRelationshipMetas = {
    'familia': RelationshipMeta<Familia>(
      name: 'familia',
      inverseName: 'persons',
      type: 'familia',
      kind: 'BelongsTo',
      instance: (_) => (_ as Person).familia,
    )
  };

  @override
  Map<String, RelationshipMeta> get relationshipMetas =>
      _kPersonRelationshipMetas;

  @override
  Person deserializeLocal(map, {String? key}) {
    map = transformDeserialize(map);
    return internalWrapStopInit(() => Person.fromJson(map), key: key);
  }

  @override
  Map<String, dynamic> serializeLocal(model, {bool withRelationships = true}) {
    final map = model.toJson();
    return transformSerialize(map, withRelationships: withRelationships);
  }
}

final _peopleFinders = <String, dynamic>{};

class $PersonAdapter = Adapter<Person>
    with
        _$PersonAdapter,
        PersonLoginAdapter,
        GenericDoesNothingAdapter<Person>,
        YetAnotherLoginAdapter;

final peopleAdapterProvider = Provider<Adapter<Person>>(
    (ref) => $PersonAdapter(ref, InternalHolder(_peopleFinders)));

extension PersonAdapterX on Adapter<Person> {
  PersonLoginAdapter get personLoginAdapter => this as PersonLoginAdapter;
  GenericDoesNothingAdapter<Person> get genericDoesNothingAdapter =>
      this as GenericDoesNothingAdapter<Person>;
  YetAnotherLoginAdapter get yetAnotherLoginAdapter =>
      this as YetAnotherLoginAdapter;
}

extension PersonRelationshipGraphNodeX on RelationshipGraphNode<Person> {
  RelationshipGraphNode<Familia> get familia {
    final meta = _$PersonAdapter._kPersonRelationshipMetas['familia']
        as RelationshipMeta<Familia>;
    return meta.clone(
        parent: this is RelationshipMeta ? this as RelationshipMeta : null);
  }
}
