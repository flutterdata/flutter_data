// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target

part of 'book.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

BookAuthor _$BookAuthorFromJson(Map<String, dynamic> json) {
  return _BookAuthor.fromJson(json);
}

/// @nodoc
mixin _$BookAuthor {
  int get id => throw _privateConstructorUsedError;
  String? get name => throw _privateConstructorUsedError;
  HasMany<Book> get books => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $BookAuthorCopyWith<BookAuthor> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BookAuthorCopyWith<$Res> {
  factory $BookAuthorCopyWith(
          BookAuthor value, $Res Function(BookAuthor) then) =
      _$BookAuthorCopyWithImpl<$Res>;
  $Res call({int id, String? name, HasMany<Book> books});
}

/// @nodoc
class _$BookAuthorCopyWithImpl<$Res> implements $BookAuthorCopyWith<$Res> {
  _$BookAuthorCopyWithImpl(this._value, this._then);

  final BookAuthor _value;
  // ignore: unused_field
  final $Res Function(BookAuthor) _then;

  @override
  $Res call({
    Object? id = freezed,
    Object? name = freezed,
    Object? books = freezed,
  }) {
    return _then(_value.copyWith(
      id: id == freezed
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name: name == freezed
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      books: books == freezed
          ? _value.books
          : books // ignore: cast_nullable_to_non_nullable
              as HasMany<Book>,
    ));
  }
}

/// @nodoc
abstract class _$$_BookAuthorCopyWith<$Res>
    implements $BookAuthorCopyWith<$Res> {
  factory _$$_BookAuthorCopyWith(
          _$_BookAuthor value, $Res Function(_$_BookAuthor) then) =
      __$$_BookAuthorCopyWithImpl<$Res>;
  @override
  $Res call({int id, String? name, HasMany<Book> books});
}

/// @nodoc
class __$$_BookAuthorCopyWithImpl<$Res> extends _$BookAuthorCopyWithImpl<$Res>
    implements _$$_BookAuthorCopyWith<$Res> {
  __$$_BookAuthorCopyWithImpl(
      _$_BookAuthor _value, $Res Function(_$_BookAuthor) _then)
      : super(_value, (v) => _then(v as _$_BookAuthor));

  @override
  _$_BookAuthor get _value => super._value as _$_BookAuthor;

  @override
  $Res call({
    Object? id = freezed,
    Object? name = freezed,
    Object? books = freezed,
  }) {
    return _then(_$_BookAuthor(
      id: id == freezed
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name: name == freezed
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      books: books == freezed
          ? _value.books
          : books // ignore: cast_nullable_to_non_nullable
              as HasMany<Book>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_BookAuthor extends _BookAuthor {
  _$_BookAuthor({required this.id, this.name, required this.books}) : super._();

  factory _$_BookAuthor.fromJson(Map<String, dynamic> json) =>
      _$$_BookAuthorFromJson(json);

  @override
  final int id;
  @override
  final String? name;
  @override
  final HasMany<Book> books;

  @override
  String toString() {
    return 'BookAuthor(id: $id, name: $name, books: $books)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_BookAuthor &&
            const DeepCollectionEquality().equals(other.id, id) &&
            const DeepCollectionEquality().equals(other.name, name) &&
            const DeepCollectionEquality().equals(other.books, books));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(id),
      const DeepCollectionEquality().hash(name),
      const DeepCollectionEquality().hash(books));

  @JsonKey(ignore: true)
  @override
  _$$_BookAuthorCopyWith<_$_BookAuthor> get copyWith =>
      __$$_BookAuthorCopyWithImpl<_$_BookAuthor>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_BookAuthorToJson(this);
  }
}

abstract class _BookAuthor extends BookAuthor {
  factory _BookAuthor(
      {required final int id,
      final String? name,
      required final HasMany<Book> books}) = _$_BookAuthor;
  _BookAuthor._() : super._();

  factory _BookAuthor.fromJson(Map<String, dynamic> json) =
      _$_BookAuthor.fromJson;

  @override
  int get id => throw _privateConstructorUsedError;
  @override
  String? get name => throw _privateConstructorUsedError;
  @override
  HasMany<Book> get books => throw _privateConstructorUsedError;
  @override
  @JsonKey(ignore: true)
  _$$_BookAuthorCopyWith<_$_BookAuthor> get copyWith =>
      throw _privateConstructorUsedError;
}

Book _$BookFromJson(Map<String, dynamic> json) {
  return _Book.fromJson(json);
}

/// @nodoc
mixin _$Book {
  int get id => throw _privateConstructorUsedError;
  String? get title => throw _privateConstructorUsedError;
  int get numberOfSales => throw _privateConstructorUsedError;
  @JsonKey(name: 'original_author_id')
  BelongsTo<BookAuthor>? get originalAuthor =>
      throw _privateConstructorUsedError;
  BelongsTo<House>? get house => throw _privateConstructorUsedError;
  HasMany<Person> get ardentSupporters => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $BookCopyWith<Book> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BookCopyWith<$Res> {
  factory $BookCopyWith(Book value, $Res Function(Book) then) =
      _$BookCopyWithImpl<$Res>;
  $Res call(
      {int id,
      String? title,
      int numberOfSales,
      @JsonKey(name: 'original_author_id')
          BelongsTo<BookAuthor>? originalAuthor,
      BelongsTo<House>? house,
      HasMany<Person> ardentSupporters});
}

/// @nodoc
class _$BookCopyWithImpl<$Res> implements $BookCopyWith<$Res> {
  _$BookCopyWithImpl(this._value, this._then);

  final Book _value;
  // ignore: unused_field
  final $Res Function(Book) _then;

  @override
  $Res call({
    Object? id = freezed,
    Object? title = freezed,
    Object? numberOfSales = freezed,
    Object? originalAuthor = freezed,
    Object? house = freezed,
    Object? ardentSupporters = freezed,
  }) {
    return _then(_value.copyWith(
      id: id == freezed
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      title: title == freezed
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String?,
      numberOfSales: numberOfSales == freezed
          ? _value.numberOfSales
          : numberOfSales // ignore: cast_nullable_to_non_nullable
              as int,
      originalAuthor: originalAuthor == freezed
          ? _value.originalAuthor
          : originalAuthor // ignore: cast_nullable_to_non_nullable
              as BelongsTo<BookAuthor>?,
      house: house == freezed
          ? _value.house
          : house // ignore: cast_nullable_to_non_nullable
              as BelongsTo<House>?,
      ardentSupporters: ardentSupporters == freezed
          ? _value.ardentSupporters
          : ardentSupporters // ignore: cast_nullable_to_non_nullable
              as HasMany<Person>,
    ));
  }
}

/// @nodoc
abstract class _$$_BookCopyWith<$Res> implements $BookCopyWith<$Res> {
  factory _$$_BookCopyWith(_$_Book value, $Res Function(_$_Book) then) =
      __$$_BookCopyWithImpl<$Res>;
  @override
  $Res call(
      {int id,
      String? title,
      int numberOfSales,
      @JsonKey(name: 'original_author_id')
          BelongsTo<BookAuthor>? originalAuthor,
      BelongsTo<House>? house,
      HasMany<Person> ardentSupporters});
}

/// @nodoc
class __$$_BookCopyWithImpl<$Res> extends _$BookCopyWithImpl<$Res>
    implements _$$_BookCopyWith<$Res> {
  __$$_BookCopyWithImpl(_$_Book _value, $Res Function(_$_Book) _then)
      : super(_value, (v) => _then(v as _$_Book));

  @override
  _$_Book get _value => super._value as _$_Book;

  @override
  $Res call({
    Object? id = freezed,
    Object? title = freezed,
    Object? numberOfSales = freezed,
    Object? originalAuthor = freezed,
    Object? house = freezed,
    Object? ardentSupporters = freezed,
  }) {
    return _then(_$_Book(
      id: id == freezed
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      title: title == freezed
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String?,
      numberOfSales: numberOfSales == freezed
          ? _value.numberOfSales
          : numberOfSales // ignore: cast_nullable_to_non_nullable
              as int,
      originalAuthor: originalAuthor == freezed
          ? _value.originalAuthor
          : originalAuthor // ignore: cast_nullable_to_non_nullable
              as BelongsTo<BookAuthor>?,
      house: house == freezed
          ? _value.house
          : house // ignore: cast_nullable_to_non_nullable
              as BelongsTo<House>?,
      ardentSupporters: ardentSupporters == freezed
          ? _value.ardentSupporters
          : ardentSupporters // ignore: cast_nullable_to_non_nullable
              as HasMany<Person>,
    ));
  }
}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class _$_Book extends _Book {
  _$_Book(
      {required this.id,
      this.title,
      this.numberOfSales = 0,
      @JsonKey(name: 'original_author_id') this.originalAuthor,
      this.house,
      required this.ardentSupporters})
      : super._();

  factory _$_Book.fromJson(Map<String, dynamic> json) => _$$_BookFromJson(json);

  @override
  final int id;
  @override
  final String? title;
  @override
  @JsonKey()
  final int numberOfSales;
  @override
  @JsonKey(name: 'original_author_id')
  final BelongsTo<BookAuthor>? originalAuthor;
  @override
  final BelongsTo<House>? house;
  @override
  final HasMany<Person> ardentSupporters;

  @override
  String toString() {
    return 'Book(id: $id, title: $title, numberOfSales: $numberOfSales, originalAuthor: $originalAuthor, house: $house, ardentSupporters: $ardentSupporters)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_Book &&
            const DeepCollectionEquality().equals(other.id, id) &&
            const DeepCollectionEquality().equals(other.title, title) &&
            const DeepCollectionEquality()
                .equals(other.numberOfSales, numberOfSales) &&
            const DeepCollectionEquality()
                .equals(other.originalAuthor, originalAuthor) &&
            const DeepCollectionEquality().equals(other.house, house) &&
            const DeepCollectionEquality()
                .equals(other.ardentSupporters, ardentSupporters));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(id),
      const DeepCollectionEquality().hash(title),
      const DeepCollectionEquality().hash(numberOfSales),
      const DeepCollectionEquality().hash(originalAuthor),
      const DeepCollectionEquality().hash(house),
      const DeepCollectionEquality().hash(ardentSupporters));

  @JsonKey(ignore: true)
  @override
  _$$_BookCopyWith<_$_Book> get copyWith =>
      __$$_BookCopyWithImpl<_$_Book>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_BookToJson(this);
  }
}

abstract class _Book extends Book {
  factory _Book(
      {required final int id,
      final String? title,
      final int numberOfSales,
      @JsonKey(name: 'original_author_id')
          final BelongsTo<BookAuthor>? originalAuthor,
      final BelongsTo<House>? house,
      required final HasMany<Person> ardentSupporters}) = _$_Book;
  _Book._() : super._();

  factory _Book.fromJson(Map<String, dynamic> json) = _$_Book.fromJson;

  @override
  int get id => throw _privateConstructorUsedError;
  @override
  String? get title => throw _privateConstructorUsedError;
  @override
  int get numberOfSales => throw _privateConstructorUsedError;
  @override
  @JsonKey(name: 'original_author_id')
  BelongsTo<BookAuthor>? get originalAuthor =>
      throw _privateConstructorUsedError;
  @override
  BelongsTo<House>? get house => throw _privateConstructorUsedError;
  @override
  HasMany<Person> get ardentSupporters => throw _privateConstructorUsedError;
  @override
  @JsonKey(ignore: true)
  _$$_BookCopyWith<_$_Book> get copyWith => throw _privateConstructorUsedError;
}
