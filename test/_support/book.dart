import 'package:flutter_data/flutter_data.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'book.freezed.dart';
part 'book.g.dart';

@freezed
@DataRepository([AuthorAdapter], remote: false)
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

mixin AuthorAdapter on RemoteAdapter<Author> {
  @override
  String get type => 'writers';
}
