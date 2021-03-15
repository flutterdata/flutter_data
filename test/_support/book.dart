import 'package:flutter_data/flutter_data.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'book.freezed.dart';
part 'book.g.dart';

@freezed
@DataRepository([])
abstract class Author with DataModel<Author>, _$Author {
  @With.fromString('DataModel<Author>')
  factory Author({
    int id,
    String name,
    HasMany<Book> books,
  }) = _Author;
  factory Author.fromJson(Map<String, dynamic> json) => _$AuthorFromJson(json);
}

@freezed
@DataRepository([])
abstract class Book with DataModel<Book>, _$Book {
  @With.fromString('DataModel<Book>')
  factory Book({
    int id,
    String title,
    BelongsTo<Author> author,
  }) = _Book;
  factory Book.fromJson(Map<String, dynamic> json) => _$BookFromJson(json);
}

@freezed
abstract class Hotel with _$Hotel {
  factory Hotel({
    int id,
    String name,
    List<Room> room,
  }) = _Hotel;
  factory Hotel.fromJson(Map<String, dynamic> json) => _$HotelFromJson(json);
}

@freezed
abstract class Room with _$Room {
  factory Room({
    int id,
    String name,
    Hotel hotel,
  }) = _Room;
  factory Room.fromJson(Map<String, dynamic> json) => _$RoomFromJson(json);
}
