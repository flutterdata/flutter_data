// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies

part of 'book.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;
Author _$AuthorFromJson(Map<String, dynamic> json) {
  return _Author.fromJson(json);
}

/// @nodoc
class _$AuthorTearOff {
  const _$AuthorTearOff();

// ignore: unused_element
  _Author call({int id, String name, HasMany<Book> books}) {
    return _Author(
      id: id,
      name: name,
      books: books,
    );
  }

// ignore: unused_element
  Author fromJson(Map<String, Object> json) {
    return Author.fromJson(json);
  }
}

/// @nodoc
// ignore: unused_element
const $Author = _$AuthorTearOff();

/// @nodoc
mixin _$Author {
  int get id;
  String get name;
  HasMany<Book> get books;

  Map<String, dynamic> toJson();
  $AuthorCopyWith<Author> get copyWith;
}

/// @nodoc
abstract class $AuthorCopyWith<$Res> {
  factory $AuthorCopyWith(Author value, $Res Function(Author) then) =
      _$AuthorCopyWithImpl<$Res>;
  $Res call({int id, String name, HasMany<Book> books});
}

/// @nodoc
class _$AuthorCopyWithImpl<$Res> implements $AuthorCopyWith<$Res> {
  _$AuthorCopyWithImpl(this._value, this._then);

  final Author _value;
  // ignore: unused_field
  final $Res Function(Author) _then;

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
abstract class _$AuthorCopyWith<$Res> implements $AuthorCopyWith<$Res> {
  factory _$AuthorCopyWith(_Author value, $Res Function(_Author) then) =
      __$AuthorCopyWithImpl<$Res>;
  @override
  $Res call({int id, String name, HasMany<Book> books});
}

/// @nodoc
class __$AuthorCopyWithImpl<$Res> extends _$AuthorCopyWithImpl<$Res>
    implements _$AuthorCopyWith<$Res> {
  __$AuthorCopyWithImpl(_Author _value, $Res Function(_Author) _then)
      : super(_value, (v) => _then(v as _Author));

  @override
  _Author get _value => super._value as _Author;

  @override
  $Res call({
    Object id = freezed,
    Object name = freezed,
    Object books = freezed,
  }) {
    return _then(_Author(
      id: id == freezed ? _value.id : id as int,
      name: name == freezed ? _value.name : name as String,
      books: books == freezed ? _value.books : books as HasMany<Book>,
    ));
  }
}

@JsonSerializable()
@With.fromString('DataModel<Author>')

/// @nodoc
class _$_Author with DataModel<Author> implements _Author {
  _$_Author({this.id, this.name, this.books});

  factory _$_Author.fromJson(Map<String, dynamic> json) =>
      _$_$_AuthorFromJson(json);

  @override
  final int id;
  @override
  final String name;
  @override
  final HasMany<Book> books;

  @override
  String toString() {
    return 'Author(id: $id, name: $name, books: $books)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _Author &&
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
  _$AuthorCopyWith<_Author> get copyWith =>
      __$AuthorCopyWithImpl<_Author>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$_$_AuthorToJson(this);
  }
}

abstract class _Author implements Author, DataModel<Author> {
  factory _Author({int id, String name, HasMany<Book> books}) = _$_Author;

  factory _Author.fromJson(Map<String, dynamic> json) = _$_Author.fromJson;

  @override
  int get id;
  @override
  String get name;
  @override
  HasMany<Book> get books;
  @override
  _$AuthorCopyWith<_Author> get copyWith;
}

Book _$BookFromJson(Map<String, dynamic> json) {
  return _Book.fromJson(json);
}

/// @nodoc
class _$BookTearOff {
  const _$BookTearOff();

// ignore: unused_element
  _Book call({int id, String title, BelongsTo<Author> author}) {
    return _Book(
      id: id,
      title: title,
      author: author,
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
  BelongsTo<Author> get author;

  Map<String, dynamic> toJson();
  $BookCopyWith<Book> get copyWith;
}

/// @nodoc
abstract class $BookCopyWith<$Res> {
  factory $BookCopyWith(Book value, $Res Function(Book) then) =
      _$BookCopyWithImpl<$Res>;
  $Res call({int id, String title, BelongsTo<Author> author});
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
    Object author = freezed,
  }) {
    return _then(_value.copyWith(
      id: id == freezed ? _value.id : id as int,
      title: title == freezed ? _value.title : title as String,
      author: author == freezed ? _value.author : author as BelongsTo<Author>,
    ));
  }
}

/// @nodoc
abstract class _$BookCopyWith<$Res> implements $BookCopyWith<$Res> {
  factory _$BookCopyWith(_Book value, $Res Function(_Book) then) =
      __$BookCopyWithImpl<$Res>;
  @override
  $Res call({int id, String title, BelongsTo<Author> author});
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
    Object author = freezed,
  }) {
    return _then(_Book(
      id: id == freezed ? _value.id : id as int,
      title: title == freezed ? _value.title : title as String,
      author: author == freezed ? _value.author : author as BelongsTo<Author>,
    ));
  }
}

@JsonSerializable()
@With.fromString('DataModel<Book>')

/// @nodoc
class _$_Book with DataModel<Book> implements _Book {
  _$_Book({this.id, this.title, this.author});

  factory _$_Book.fromJson(Map<String, dynamic> json) =>
      _$_$_BookFromJson(json);

  @override
  final int id;
  @override
  final String title;
  @override
  final BelongsTo<Author> author;

  @override
  String toString() {
    return 'Book(id: $id, title: $title, author: $author)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _Book &&
            (identical(other.id, id) ||
                const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.title, title) ||
                const DeepCollectionEquality().equals(other.title, title)) &&
            (identical(other.author, author) ||
                const DeepCollectionEquality().equals(other.author, author)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(title) ^
      const DeepCollectionEquality().hash(author);

  @override
  _$BookCopyWith<_Book> get copyWith =>
      __$BookCopyWithImpl<_Book>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$_$_BookToJson(this);
  }
}

abstract class _Book implements Book, DataModel<Book> {
  factory _Book({int id, String title, BelongsTo<Author> author}) = _$_Book;

  factory _Book.fromJson(Map<String, dynamic> json) = _$_Book.fromJson;

  @override
  int get id;
  @override
  String get title;
  @override
  BelongsTo<Author> get author;
  @override
  _$BookCopyWith<_Book> get copyWith;
}

Hotel _$HotelFromJson(Map<String, dynamic> json) {
  return _Hotel.fromJson(json);
}

/// @nodoc
class _$HotelTearOff {
  const _$HotelTearOff();

// ignore: unused_element
  _Hotel call({int id, String name, List<Room> room}) {
    return _Hotel(
      id: id,
      name: name,
      room: room,
    );
  }

// ignore: unused_element
  Hotel fromJson(Map<String, Object> json) {
    return Hotel.fromJson(json);
  }
}

/// @nodoc
// ignore: unused_element
const $Hotel = _$HotelTearOff();

/// @nodoc
mixin _$Hotel {
  int get id;
  String get name;
  List<Room> get room;

  Map<String, dynamic> toJson();
  $HotelCopyWith<Hotel> get copyWith;
}

/// @nodoc
abstract class $HotelCopyWith<$Res> {
  factory $HotelCopyWith(Hotel value, $Res Function(Hotel) then) =
      _$HotelCopyWithImpl<$Res>;
  $Res call({int id, String name, List<Room> room});
}

/// @nodoc
class _$HotelCopyWithImpl<$Res> implements $HotelCopyWith<$Res> {
  _$HotelCopyWithImpl(this._value, this._then);

  final Hotel _value;
  // ignore: unused_field
  final $Res Function(Hotel) _then;

  @override
  $Res call({
    Object id = freezed,
    Object name = freezed,
    Object room = freezed,
  }) {
    return _then(_value.copyWith(
      id: id == freezed ? _value.id : id as int,
      name: name == freezed ? _value.name : name as String,
      room: room == freezed ? _value.room : room as List<Room>,
    ));
  }
}

/// @nodoc
abstract class _$HotelCopyWith<$Res> implements $HotelCopyWith<$Res> {
  factory _$HotelCopyWith(_Hotel value, $Res Function(_Hotel) then) =
      __$HotelCopyWithImpl<$Res>;
  @override
  $Res call({int id, String name, List<Room> room});
}

/// @nodoc
class __$HotelCopyWithImpl<$Res> extends _$HotelCopyWithImpl<$Res>
    implements _$HotelCopyWith<$Res> {
  __$HotelCopyWithImpl(_Hotel _value, $Res Function(_Hotel) _then)
      : super(_value, (v) => _then(v as _Hotel));

  @override
  _Hotel get _value => super._value as _Hotel;

  @override
  $Res call({
    Object id = freezed,
    Object name = freezed,
    Object room = freezed,
  }) {
    return _then(_Hotel(
      id: id == freezed ? _value.id : id as int,
      name: name == freezed ? _value.name : name as String,
      room: room == freezed ? _value.room : room as List<Room>,
    ));
  }
}

@JsonSerializable()

/// @nodoc
class _$_Hotel implements _Hotel {
  _$_Hotel({this.id, this.name, this.room});

  factory _$_Hotel.fromJson(Map<String, dynamic> json) =>
      _$_$_HotelFromJson(json);

  @override
  final int id;
  @override
  final String name;
  @override
  final List<Room> room;

  @override
  String toString() {
    return 'Hotel(id: $id, name: $name, room: $room)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _Hotel &&
            (identical(other.id, id) ||
                const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.name, name) ||
                const DeepCollectionEquality().equals(other.name, name)) &&
            (identical(other.room, room) ||
                const DeepCollectionEquality().equals(other.room, room)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(name) ^
      const DeepCollectionEquality().hash(room);

  @override
  _$HotelCopyWith<_Hotel> get copyWith =>
      __$HotelCopyWithImpl<_Hotel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$_$_HotelToJson(this);
  }
}

abstract class _Hotel implements Hotel {
  factory _Hotel({int id, String name, List<Room> room}) = _$_Hotel;

  factory _Hotel.fromJson(Map<String, dynamic> json) = _$_Hotel.fromJson;

  @override
  int get id;
  @override
  String get name;
  @override
  List<Room> get room;
  @override
  _$HotelCopyWith<_Hotel> get copyWith;
}

Room _$RoomFromJson(Map<String, dynamic> json) {
  return _Room.fromJson(json);
}

/// @nodoc
class _$RoomTearOff {
  const _$RoomTearOff();

// ignore: unused_element
  _Room call({int id, String name, Hotel hotel}) {
    return _Room(
      id: id,
      name: name,
      hotel: hotel,
    );
  }

// ignore: unused_element
  Room fromJson(Map<String, Object> json) {
    return Room.fromJson(json);
  }
}

/// @nodoc
// ignore: unused_element
const $Room = _$RoomTearOff();

/// @nodoc
mixin _$Room {
  int get id;
  String get name;
  Hotel get hotel;

  Map<String, dynamic> toJson();
  $RoomCopyWith<Room> get copyWith;
}

/// @nodoc
abstract class $RoomCopyWith<$Res> {
  factory $RoomCopyWith(Room value, $Res Function(Room) then) =
      _$RoomCopyWithImpl<$Res>;
  $Res call({int id, String name, Hotel hotel});

  $HotelCopyWith<$Res> get hotel;
}

/// @nodoc
class _$RoomCopyWithImpl<$Res> implements $RoomCopyWith<$Res> {
  _$RoomCopyWithImpl(this._value, this._then);

  final Room _value;
  // ignore: unused_field
  final $Res Function(Room) _then;

  @override
  $Res call({
    Object id = freezed,
    Object name = freezed,
    Object hotel = freezed,
  }) {
    return _then(_value.copyWith(
      id: id == freezed ? _value.id : id as int,
      name: name == freezed ? _value.name : name as String,
      hotel: hotel == freezed ? _value.hotel : hotel as Hotel,
    ));
  }

  @override
  $HotelCopyWith<$Res> get hotel {
    if (_value.hotel == null) {
      return null;
    }
    return $HotelCopyWith<$Res>(_value.hotel, (value) {
      return _then(_value.copyWith(hotel: value));
    });
  }
}

/// @nodoc
abstract class _$RoomCopyWith<$Res> implements $RoomCopyWith<$Res> {
  factory _$RoomCopyWith(_Room value, $Res Function(_Room) then) =
      __$RoomCopyWithImpl<$Res>;
  @override
  $Res call({int id, String name, Hotel hotel});

  @override
  $HotelCopyWith<$Res> get hotel;
}

/// @nodoc
class __$RoomCopyWithImpl<$Res> extends _$RoomCopyWithImpl<$Res>
    implements _$RoomCopyWith<$Res> {
  __$RoomCopyWithImpl(_Room _value, $Res Function(_Room) _then)
      : super(_value, (v) => _then(v as _Room));

  @override
  _Room get _value => super._value as _Room;

  @override
  $Res call({
    Object id = freezed,
    Object name = freezed,
    Object hotel = freezed,
  }) {
    return _then(_Room(
      id: id == freezed ? _value.id : id as int,
      name: name == freezed ? _value.name : name as String,
      hotel: hotel == freezed ? _value.hotel : hotel as Hotel,
    ));
  }
}

@JsonSerializable()

/// @nodoc
class _$_Room implements _Room {
  _$_Room({this.id, this.name, this.hotel});

  factory _$_Room.fromJson(Map<String, dynamic> json) =>
      _$_$_RoomFromJson(json);

  @override
  final int id;
  @override
  final String name;
  @override
  final Hotel hotel;

  @override
  String toString() {
    return 'Room(id: $id, name: $name, hotel: $hotel)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _Room &&
            (identical(other.id, id) ||
                const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.name, name) ||
                const DeepCollectionEquality().equals(other.name, name)) &&
            (identical(other.hotel, hotel) ||
                const DeepCollectionEquality().equals(other.hotel, hotel)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(name) ^
      const DeepCollectionEquality().hash(hotel);

  @override
  _$RoomCopyWith<_Room> get copyWith =>
      __$RoomCopyWithImpl<_Room>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$_$_RoomToJson(this);
  }
}

abstract class _Room implements Room {
  factory _Room({int id, String name, Hotel hotel}) = _$_Room;

  factory _Room.fromJson(Map<String, dynamic> json) = _$_Room.fromJson;

  @override
  int get id;
  @override
  String get name;
  @override
  Hotel get hotel;
  @override
  _$RoomCopyWith<_Room> get copyWith;
}
