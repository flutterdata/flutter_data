// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies

part of 'book.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;
BookAuthor _$BookAuthorFromJson(Map<String, dynamic> json) {
  return _BookAuthor.fromJson(json);
}

/// @nodoc
class _$BookAuthorTearOff {
  const _$BookAuthorTearOff();

// ignore: unused_element
  _BookAuthor call({int id, String name, HasMany<Book> books}) {
    return _BookAuthor(
      id: id,
      name: name,
      books: books,
    );
  }

// ignore: unused_element
  BookAuthor fromJson(Map<String, Object> json) {
    return BookAuthor.fromJson(json);
  }
}

/// @nodoc
// ignore: unused_element
const $BookAuthor = _$BookAuthorTearOff();

/// @nodoc
mixin _$BookAuthor {
  int get id;
  String get name;
  HasMany<Book> get books;

  Map<String, dynamic> toJson();
  $BookAuthorCopyWith<BookAuthor> get copyWith;
}

/// @nodoc
abstract class $BookAuthorCopyWith<$Res> {
  factory $BookAuthorCopyWith(
          BookAuthor value, $Res Function(BookAuthor) then) =
      _$BookAuthorCopyWithImpl<$Res>;
  $Res call({int id, String name, HasMany<Book> books});
}

/// @nodoc
class _$BookAuthorCopyWithImpl<$Res> implements $BookAuthorCopyWith<$Res> {
  _$BookAuthorCopyWithImpl(this._value, this._then);

  final BookAuthor _value;
  // ignore: unused_field
  final $Res Function(BookAuthor) _then;

  @override
  $Res call({
    Object id = freezed,
    Object name = freezed,
    Object books = freezed,
  }) {
    return _then(_value.copyWith(
      id: id == freezed ? _value.id : id as int,
      name: name == freezed ? _value.name : name as String,
      books: books == freezed ? _value.books : books as HasMany<Book>,
    ));
  }
}

/// @nodoc
abstract class _$BookAuthorCopyWith<$Res> implements $BookAuthorCopyWith<$Res> {
  factory _$BookAuthorCopyWith(
          _BookAuthor value, $Res Function(_BookAuthor) then) =
      __$BookAuthorCopyWithImpl<$Res>;
  @override
  $Res call({int id, String name, HasMany<Book> books});
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
    Object id = freezed,
    Object name = freezed,
    Object books = freezed,
  }) {
    return _then(_BookAuthor(
      id: id == freezed ? _value.id : id as int,
      name: name == freezed ? _value.name : name as String,
      books: books == freezed ? _value.books : books as HasMany<Book>,
    ));
  }
}

@JsonSerializable()
@With.fromString('DataModel<BookAuthor>')

/// @nodoc
class _$_BookAuthor with DataModel<BookAuthor> implements _BookAuthor {
  _$_BookAuthor({this.id, this.name, this.books});

  factory _$_BookAuthor.fromJson(Map<String, dynamic> json) =>
      _$_$_BookAuthorFromJson(json);

  @override
  final int id;
  @override
  final String name;
  @override
  final HasMany<Book> books;

  @override
  String toString() {
    return 'BookAuthor(id: $id, name: $name, books: $books)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _BookAuthor &&
            (identical(other.id, id) ||
                const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.name, name) ||
                const DeepCollectionEquality().equals(other.name, name)) &&
            (identical(other.books, books) ||
                const DeepCollectionEquality().equals(other.books, books)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(name) ^
      const DeepCollectionEquality().hash(books);

  @override
  _$BookAuthorCopyWith<_BookAuthor> get copyWith =>
      __$BookAuthorCopyWithImpl<_BookAuthor>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$_$_BookAuthorToJson(this);
  }
}

abstract class _BookAuthor implements BookAuthor, DataModel<BookAuthor> {
  factory _BookAuthor({int id, String name, HasMany<Book> books}) =
      _$_BookAuthor;

  factory _BookAuthor.fromJson(Map<String, dynamic> json) =
      _$_BookAuthor.fromJson;

  @override
  int get id;
  @override
  String get name;
  @override
  HasMany<Book> get books;
  @override
  _$BookAuthorCopyWith<_BookAuthor> get copyWith;
}

Book _$BookFromJson(Map<String, dynamic> json) {
  return _Book.fromJson(json);
}

/// @nodoc
class _$BookTearOff {
  const _$BookTearOff();

// ignore: unused_element
  _Book call(
      {int id,
      String title,
      int numberOfSales,
      @JsonKey(name: 'original_author') BelongsTo<BookAuthor> originalAuthor}) {
    return _Book(
      id: id,
      title: title,
      numberOfSales: numberOfSales,
      originalAuthor: originalAuthor,
    );
  }

// ignore: unused_element
  Book fromJson(Map<String, Object> json) {
    return Book.fromJson(json);
  }
}

/// @nodoc
// ignore: unused_element
const $Book = _$BookTearOff();

/// @nodoc
mixin _$Book {
  int get id;
  String get title;
  int get numberOfSales;
  @JsonKey(name: 'original_author')
  BelongsTo<BookAuthor> get originalAuthor;

  Map<String, dynamic> toJson();
  $BookCopyWith<Book> get copyWith;
}

/// @nodoc
abstract class $BookCopyWith<$Res> {
  factory $BookCopyWith(Book value, $Res Function(Book) then) =
      _$BookCopyWithImpl<$Res>;
  $Res call(
      {int id,
      String title,
      int numberOfSales,
      @JsonKey(name: 'original_author') BelongsTo<BookAuthor> originalAuthor});
}

/// @nodoc
class _$BookCopyWithImpl<$Res> implements $BookCopyWith<$Res> {
  _$BookCopyWithImpl(this._value, this._then);

  final Book _value;
  // ignore: unused_field
  final $Res Function(Book) _then;

  @override
  $Res call({
    Object id = freezed,
    Object title = freezed,
    Object numberOfSales = freezed,
    Object originalAuthor = freezed,
  }) {
    return _then(_value.copyWith(
      id: id == freezed ? _value.id : id as int,
      title: title == freezed ? _value.title : title as String,
      numberOfSales: numberOfSales == freezed
          ? _value.numberOfSales
          : numberOfSales as int,
      originalAuthor: originalAuthor == freezed
          ? _value.originalAuthor
          : originalAuthor as BelongsTo<BookAuthor>,
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
      String title,
      int numberOfSales,
      @JsonKey(name: 'original_author') BelongsTo<BookAuthor> originalAuthor});
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
    Object id = freezed,
    Object title = freezed,
    Object numberOfSales = freezed,
    Object originalAuthor = freezed,
  }) {
    return _then(_Book(
      id: id == freezed ? _value.id : id as int,
      title: title == freezed ? _value.title : title as String,
      numberOfSales: numberOfSales == freezed
          ? _value.numberOfSales
          : numberOfSales as int,
      originalAuthor: originalAuthor == freezed
          ? _value.originalAuthor
          : originalAuthor as BelongsTo<BookAuthor>,
    ));
  }
}

@With.fromString('DataModel<Book>')
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)

/// @nodoc
class _$_Book with DataModel<Book> implements _Book {
  _$_Book(
      {this.id,
      this.title,
      this.numberOfSales,
      @JsonKey(name: 'original_author') this.originalAuthor});

  factory _$_Book.fromJson(Map<String, dynamic> json) =>
      _$_$_BookFromJson(json);

  @override
  final int id;
  @override
  final String title;
  @override
  final int numberOfSales;
  @override
  @JsonKey(name: 'original_author')
  final BelongsTo<BookAuthor> originalAuthor;

  @override
  String toString() {
    return 'Book(id: $id, title: $title, numberOfSales: $numberOfSales, originalAuthor: $originalAuthor)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _Book &&
            (identical(other.id, id) ||
                const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.title, title) ||
                const DeepCollectionEquality().equals(other.title, title)) &&
            (identical(other.numberOfSales, numberOfSales) ||
                const DeepCollectionEquality()
                    .equals(other.numberOfSales, numberOfSales)) &&
            (identical(other.originalAuthor, originalAuthor) ||
                const DeepCollectionEquality()
                    .equals(other.originalAuthor, originalAuthor)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(title) ^
      const DeepCollectionEquality().hash(numberOfSales) ^
      const DeepCollectionEquality().hash(originalAuthor);

  @override
  _$BookCopyWith<_Book> get copyWith =>
      __$BookCopyWithImpl<_Book>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$_$_BookToJson(this);
  }
}

abstract class _Book implements Book, DataModel<Book> {
  factory _Book(
      {int id,
      String title,
      int numberOfSales,
      @JsonKey(name: 'original_author')
          BelongsTo<BookAuthor> originalAuthor}) = _$_Book;

  factory _Book.fromJson(Map<String, dynamic> json) = _$_Book.fromJson;

  @override
  int get id;
  @override
  String get title;
  @override
  int get numberOfSales;
  @override
  @JsonKey(name: 'original_author')
  BelongsTo<BookAuthor> get originalAuthor;
  @override
  _$BookCopyWith<_Book> get copyWith;
}
