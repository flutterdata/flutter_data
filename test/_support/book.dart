import 'package:flutter_data/flutter_data.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'book.freezed.dart';
part 'book.g.dart';

@freezed
@DataRepository([BookAuthorAdapter], remote: false)
abstract class BookAuthor with DataModel<BookAuthor>, _$BookAuthor {
  @With.fromString('DataModel<BookAuthor>')
  factory BookAuthor({
    int id,
    String name,
    HasMany<Book> books,
  }) = _BookAuthor;
  factory BookAuthor.fromJson(Map<String, dynamic> json) =>
      _$BookAuthorFromJson(json);
}

@freezed
@DataRepository([])
abstract class Book with DataModel<Book>, _$Book {
  @With.fromString('DataModel<Book>')
  @JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
  factory Book({
    int id,
    String title,
    int numberOfSales,
    @JsonKey(name: 'original_author') BelongsTo<BookAuthor> originalAuthor,
  }) = _Book;
  factory Book.fromJson(Map<String, dynamic> json) => _$BookFromJson(json);
}

mixin BookAuthorAdapter on RemoteAdapter<BookAuthor> {
  @override
  String get type => 'writers';
}
