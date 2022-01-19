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
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more informations: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

BookAuthor _$BookAuthorFromJson(Map<String, dynamic> json) {
  return _BookAuthor.fromJson(json);
}

/// @nodoc
class _$BookAuthorTearOff {
  const _$BookAuthorTearOff();

  _BookAuthor call({required int id, String? name, HasMany<Book>? books}) {
    return _BookAuthor(
      id: id,
      name: name,
      books: books,
    );
  }

  BookAuthor fromJson(Map<String, Object?> json) {
    return BookAuthor.fromJson(json);
  }
}

/// @nodoc
const $BookAuthor = _$BookAuthorTearOff();

/// @nodoc
mixin _$BookAuthor {
  int get id => throw _privateConstructorUsedError;
  String? get name => throw _privateConstructorUsedError;
  HasMany<Book>? get books => throw _privateConstructorUsedError;

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
  $Res call({int id, String? name, HasMany<Book>? books});
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
              as HasMany<Book>?,
    ));
  }
}

/// @nodoc
abstract class _$BookAuthorCopyWith<$Res> implements $BookAuthorCopyWith<$Res> {
  factory _$BookAuthorCopyWith(
          _BookAuthor value, $Res Function(_BookAuthor) then) =
      __$BookAuthorCopyWithImpl<$Res>;
  @override
  $Res call({int id, String? name, HasMany<Book>? books});
}

/// @nodoc
class __$BookAuthorCopyWithImpl<$Res> extends _$BookAuthorCopyWithImpl<$Res>
    implements _$BookAuthorCopyWith<$Res> {
  __$BookAuthorCopyWithImpl(
      _BookAuthor _value, $Res Function(_BookAuthor) _then)
      : super(_value, (v) => _then(v as _BookAuthor));

  @override
  _BookAuthor get _value => super._value as _BookAuthor;

  @override
  $Res call({
    Object? id = freezed,
    Object? name = freezed,
    Object? books = freezed,
  }) {
    return _then(_BookAuthor(
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
              as HasMany<Book>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_BookAuthor extends _BookAuthor {
  _$_BookAuthor({required this.id, this.name, this.books}) : super._();

  factory _$_BookAuthor.fromJson(Map<String, dynamic> json) =>
      _$$_BookAuthorFromJson(json);

  @override
  final int id;
  @override
  final String? name;
  @override
  final HasMany<Book>? books;

  @override
  String toString() {
    return 'BookAuthor(id: $id, name: $name, books: $books)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _BookAuthor &&
            const DeepCollectionEquality().equals(other.id, id) &&
            const DeepCollectionEquality().equals(other.name, name) &&
            const DeepCollectionEquality().equals(other.books, books));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(id),
      const DeepCollectionEquality().hash(name),
      const DeepCollectionEquality().hash(books));

  @JsonKey(ignore: true)
  @override
  _$BookAuthorCopyWith<_BookAuthor> get copyWith =>
      __$BookAuthorCopyWithImpl<_BookAuthor>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_BookAuthorToJson(this);
  }
}

abstract class _BookAuthor extends BookAuthor {
  factory _BookAuthor({required int id, String? name, HasMany<Book>? books}) =
      _$_BookAuthor;
  _BookAuthor._() : super._();

  factory _BookAuthor.fromJson(Map<String, dynamic> json) =
      _$_BookAuthor.fromJson;

  @override
  int get id;
  @override
  String? get name;
  @override
  HasMany<Book>? get books;
  @override
  @JsonKey(ignore: true)
  _$BookAuthorCopyWith<_BookAuthor> get copyWith =>
      throw _privateConstructorUsedError;
}

Book _$BookFromJson(Map<String, dynamic> json) {
  return _Book.fromJson(json);
}

/// @nodoc
class _$BookTearOff {
  const _$BookTearOff();

  _Book call(
      {required int id,
      String? title,
      int numberOfSales = 0,
      @JsonKey(name: 'original_author')
          BelongsTo<BookAuthor>? originalAuthor}) {
    return _Book(
      id: id,
      title: title,
      numberOfSales: numberOfSales,
      originalAuthor: originalAuthor,
    );
  }

  Book fromJson(Map<String, Object?> json) {
    return Book.fromJson(json);
  }
}

/// @nodoc
const $Book = _$BookTearOff();

/// @nodoc
mixin _$Book {
  int get id => throw _privateConstructorUsedError;
  String? get title => throw _privateConstructorUsedError;
  int get numberOfSales => throw _privateConstructorUsedError;
  @JsonKey(name: 'original_author')
  BelongsTo<BookAuthor>? get originalAuthor =>
      throw _privateConstructorUsedError;

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
      @JsonKey(name: 'original_author') BelongsTo<BookAuthor>? originalAuthor});
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
    ));
  }
}

/// @nodoc
abstract class _$BookCopyWith<$Res> implements $BookCopyWith<$Res> {
  factory _$BookCopyWith(_Book value, $Res Function(_Book) then) =
      __$BookCopyWithImpl<$Res>;
  @override
  $Res call(
      {int id,
      String? title,
      int numberOfSales,
      @JsonKey(name: 'original_author') BelongsTo<BookAuthor>? originalAuthor});
}

/// @nodoc
class __$BookCopyWithImpl<$Res> extends _$BookCopyWithImpl<$Res>
    implements _$BookCopyWith<$Res> {
  __$BookCopyWithImpl(_Book _value, $Res Function(_Book) _then)
      : super(_value, (v) => _then(v as _Book));

  @override
  _Book get _value => super._value as _Book;

  @override
  $Res call({
    Object? id = freezed,
    Object? title = freezed,
    Object? numberOfSales = freezed,
    Object? originalAuthor = freezed,
  }) {
    return _then(_Book(
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
      @JsonKey(name: 'original_author') this.originalAuthor})
      : super._();

  factory _$_Book.fromJson(Map<String, dynamic> json) => _$$_BookFromJson(json);

  @override
  final int id;
  @override
  final String? title;
  @JsonKey()
  @override
  final int numberOfSales;
  @override
  @JsonKey(name: 'original_author')
  final BelongsTo<BookAuthor>? originalAuthor;

  @override
  String toString() {
    return 'Book(id: $id, title: $title, numberOfSales: $numberOfSales, originalAuthor: $originalAuthor)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Book &&
            const DeepCollectionEquality().equals(other.id, id) &&
            const DeepCollectionEquality().equals(other.title, title) &&
            const DeepCollectionEquality()
                .equals(other.numberOfSales, numberOfSales) &&
            const DeepCollectionEquality()
                .equals(other.originalAuthor, originalAuthor));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(id),
      const DeepCollectionEquality().hash(title),
      const DeepCollectionEquality().hash(numberOfSales),
      const DeepCollectionEquality().hash(originalAuthor));

  @JsonKey(ignore: true)
  @override
  _$BookCopyWith<_Book> get copyWith =>
      __$BookCopyWithImpl<_Book>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_BookToJson(this);
  }
}

abstract class _Book extends Book {
  factory _Book(
      {required int id,
      String? title,
      int numberOfSales,
      @JsonKey(name: 'original_author')
          BelongsTo<BookAuthor>? originalAuthor}) = _$_Book;
  _Book._() : super._();

  factory _Book.fromJson(Map<String, dynamic> json) = _$_Book.fromJson;

  @override
  int get id;
  @override
  String? get title;
  @override
  int get numberOfSales;
  @override
  @JsonKey(name: 'original_author')
  BelongsTo<BookAuthor>? get originalAuthor;
  @override
  @JsonKey(ignore: true)
  _$BookCopyWith<_Book> get copyWith => throw _privateConstructorUsedError;
}
