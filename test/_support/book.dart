// ignore_for_file: invalid_annotation_target

import 'package:flutter_data/flutter_data.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'book.freezed.dart';
part 'book.g.dart';

@freezed
@DataRepository([BookAuthorAdapter], remote: false)
class BookAuthor with DataModel<BookAuthor>, _$BookAuthor {
  BookAuthor._();
  factory BookAuthor({
    required int id,
    String? name,
    HasMany<Book>? books,
  }) = _BookAuthor;
  factory BookAuthor.fromJson(Map<String, dynamic> json) =>
      _$BookAuthorFromJson(json);
}

@freezed
@DataRepository([])
class Book with DataModel<Book>, _$Book {
  Book._();
  @JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
  factory Book({
    required int id,
    String? title,
    @Default(0) int numberOfSales,
    @JsonKey(name: 'original_author') BelongsTo<BookAuthor>? originalAuthor,
  }) = _Book;
  factory Book.fromJson(Map<String, dynamic> json) => _$BookFromJson(json);
}

mixin BookAuthorAdapter on RemoteAdapter<BookAuthor> {
  @override
  String get type => 'writers';

  @override
  DataStrategies<BookAuthor> get strategies =>
      super.strategies.add(finderOne: dashboard, name: 'dashboard');

  DataFinderOne<BookAuthor> get dashboard => findOne;
}
