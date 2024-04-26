// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'book.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

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
      _$BookAuthorCopyWithImpl<$Res, BookAuthor>;
  @useResult
  $Res call({int id, String? name, HasMany<Book> books});
}

/// @nodoc
class _$BookAuthorCopyWithImpl<$Res, $Val extends BookAuthor>
    implements $BookAuthorCopyWith<$Res> {
  _$BookAuthorCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = freezed,
    Object? books = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      books: null == books
          ? _value.books
          : books // ignore: cast_nullable_to_non_nullable
              as HasMany<Book>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BookAuthorImplCopyWith<$Res>
    implements $BookAuthorCopyWith<$Res> {
  factory _$$BookAuthorImplCopyWith(
          _$BookAuthorImpl value, $Res Function(_$BookAuthorImpl) then) =
      __$$BookAuthorImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int id, String? name, HasMany<Book> books});
}

/// @nodoc
class __$$BookAuthorImplCopyWithImpl<$Res>
    extends _$BookAuthorCopyWithImpl<$Res, _$BookAuthorImpl>
    implements _$$BookAuthorImplCopyWith<$Res> {
  __$$BookAuthorImplCopyWithImpl(
      _$BookAuthorImpl _value, $Res Function(_$BookAuthorImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = freezed,
    Object? books = null,
  }) {
    return _then(_$BookAuthorImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      books: null == books
          ? _value.books
          : books // ignore: cast_nullable_to_non_nullable
              as HasMany<Book>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$BookAuthorImpl extends _BookAuthor {
  _$BookAuthorImpl({required this.id, this.name, required this.books})
      : super._();

  factory _$BookAuthorImpl.fromJson(Map<String, dynamic> json) =>
      _$$BookAuthorImplFromJson(json);

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
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BookAuthorImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.books, books) || other.books == books));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, books);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$BookAuthorImplCopyWith<_$BookAuthorImpl> get copyWith =>
      __$$BookAuthorImplCopyWithImpl<_$BookAuthorImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BookAuthorImplToJson(
      this,
    );
  }
}

abstract class _BookAuthor extends BookAuthor {
  factory _BookAuthor(
      {required final int id,
      final String? name,
      required final HasMany<Book> books}) = _$BookAuthorImpl;
  _BookAuthor._() : super._();

  factory _BookAuthor.fromJson(Map<String, dynamic> json) =
      _$BookAuthorImpl.fromJson;

  @override
  int get id;
  @override
  String? get name;
  @override
  HasMany<Book> get books;
  @override
  @JsonKey(ignore: true)
  _$$BookAuthorImplCopyWith<_$BookAuthorImpl> get copyWith =>
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
      _$BookCopyWithImpl<$Res, Book>;
  @useResult
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
class _$BookCopyWithImpl<$Res, $Val extends Book>
    implements $BookCopyWith<$Res> {
  _$BookCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = freezed,
    Object? numberOfSales = null,
    Object? originalAuthor = freezed,
    Object? house = freezed,
    Object? ardentSupporters = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      title: freezed == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String?,
      numberOfSales: null == numberOfSales
          ? _value.numberOfSales
          : numberOfSales // ignore: cast_nullable_to_non_nullable
              as int,
      originalAuthor: freezed == originalAuthor
          ? _value.originalAuthor
          : originalAuthor // ignore: cast_nullable_to_non_nullable
              as BelongsTo<BookAuthor>?,
      house: freezed == house
          ? _value.house
          : house // ignore: cast_nullable_to_non_nullable
              as BelongsTo<House>?,
      ardentSupporters: null == ardentSupporters
          ? _value.ardentSupporters
          : ardentSupporters // ignore: cast_nullable_to_non_nullable
              as HasMany<Person>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BookImplCopyWith<$Res> implements $BookCopyWith<$Res> {
  factory _$$BookImplCopyWith(
          _$BookImpl value, $Res Function(_$BookImpl) then) =
      __$$BookImplCopyWithImpl<$Res>;
  @override
  @useResult
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
class __$$BookImplCopyWithImpl<$Res>
    extends _$BookCopyWithImpl<$Res, _$BookImpl>
    implements _$$BookImplCopyWith<$Res> {
  __$$BookImplCopyWithImpl(_$BookImpl _value, $Res Function(_$BookImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = freezed,
    Object? numberOfSales = null,
    Object? originalAuthor = freezed,
    Object? house = freezed,
    Object? ardentSupporters = null,
  }) {
    return _then(_$BookImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      title: freezed == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String?,
      numberOfSales: null == numberOfSales
          ? _value.numberOfSales
          : numberOfSales // ignore: cast_nullable_to_non_nullable
              as int,
      originalAuthor: freezed == originalAuthor
          ? _value.originalAuthor
          : originalAuthor // ignore: cast_nullable_to_non_nullable
              as BelongsTo<BookAuthor>?,
      house: freezed == house
          ? _value.house
          : house // ignore: cast_nullable_to_non_nullable
              as BelongsTo<House>?,
      ardentSupporters: null == ardentSupporters
          ? _value.ardentSupporters
          : ardentSupporters // ignore: cast_nullable_to_non_nullable
              as HasMany<Person>,
    ));
  }
}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class _$BookImpl extends _Book {
  _$BookImpl(
      {required this.id,
      this.title,
      this.numberOfSales = 0,
      @JsonKey(name: 'original_author_id') this.originalAuthor,
      this.house,
      required this.ardentSupporters})
      : super._();

  factory _$BookImpl.fromJson(Map<String, dynamic> json) =>
      _$$BookImplFromJson(json);

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
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BookImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.numberOfSales, numberOfSales) ||
                other.numberOfSales == numberOfSales) &&
            (identical(other.originalAuthor, originalAuthor) ||
                other.originalAuthor == originalAuthor) &&
            (identical(other.house, house) || other.house == house) &&
            (identical(other.ardentSupporters, ardentSupporters) ||
                other.ardentSupporters == ardentSupporters));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, title, numberOfSales,
      originalAuthor, house, ardentSupporters);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$BookImplCopyWith<_$BookImpl> get copyWith =>
      __$$BookImplCopyWithImpl<_$BookImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BookImplToJson(
      this,
    );
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
      required final HasMany<Person> ardentSupporters}) = _$BookImpl;
  _Book._() : super._();

  factory _Book.fromJson(Map<String, dynamic> json) = _$BookImpl.fromJson;

  @override
  int get id;
  @override
  String? get title;
  @override
  int get numberOfSales;
  @override
  @JsonKey(name: 'original_author_id')
  BelongsTo<BookAuthor>? get originalAuthor;
  @override
  BelongsTo<House>? get house;
  @override
  HasMany<Person> get ardentSupporters;
  @override
  @JsonKey(ignore: true)
  _$$BookImplCopyWith<_$BookImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Library _$LibraryFromJson(Map<String, dynamic> json) {
  return _Library.fromJson(json);
}

/// @nodoc
mixin _$Library {
  int get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  HasMany<Book> get books => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $LibraryCopyWith<Library> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LibraryCopyWith<$Res> {
  factory $LibraryCopyWith(Library value, $Res Function(Library) then) =
      _$LibraryCopyWithImpl<$Res, Library>;
  @useResult
  $Res call({int id, String name, HasMany<Book> books});
}

/// @nodoc
class _$LibraryCopyWithImpl<$Res, $Val extends Library>
    implements $LibraryCopyWith<$Res> {
  _$LibraryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? books = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      books: null == books
          ? _value.books
          : books // ignore: cast_nullable_to_non_nullable
              as HasMany<Book>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LibraryImplCopyWith<$Res> implements $LibraryCopyWith<$Res> {
  factory _$$LibraryImplCopyWith(
          _$LibraryImpl value, $Res Function(_$LibraryImpl) then) =
      __$$LibraryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int id, String name, HasMany<Book> books});
}

/// @nodoc
class __$$LibraryImplCopyWithImpl<$Res>
    extends _$LibraryCopyWithImpl<$Res, _$LibraryImpl>
    implements _$$LibraryImplCopyWith<$Res> {
  __$$LibraryImplCopyWithImpl(
      _$LibraryImpl _value, $Res Function(_$LibraryImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? books = null,
  }) {
    return _then(_$LibraryImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      books: null == books
          ? _value.books
          : books // ignore: cast_nullable_to_non_nullable
              as HasMany<Book>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LibraryImpl extends _Library {
  _$LibraryImpl({required this.id, required this.name, required this.books})
      : super._();

  factory _$LibraryImpl.fromJson(Map<String, dynamic> json) =>
      _$$LibraryImplFromJson(json);

  @override
  final int id;
  @override
  final String name;
  @override
  final HasMany<Book> books;

  @override
  String toString() {
    return 'Library(id: $id, name: $name, books: $books)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LibraryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.books, books) || other.books == books));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, books);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LibraryImplCopyWith<_$LibraryImpl> get copyWith =>
      __$$LibraryImplCopyWithImpl<_$LibraryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LibraryImplToJson(
      this,
    );
  }
}

abstract class _Library extends Library {
  factory _Library(
      {required final int id,
      required final String name,
      required final HasMany<Book> books}) = _$LibraryImpl;
  _Library._() : super._();

  factory _Library.fromJson(Map<String, dynamic> json) = _$LibraryImpl.fromJson;

  @override
  int get id;
  @override
  String get name;
  @override
  HasMany<Book> get books;
  @override
  @JsonKey(ignore: true)
  _$$LibraryImplCopyWith<_$LibraryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
