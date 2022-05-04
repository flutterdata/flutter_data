// ignore_for_file: invalid_annotation_target

import 'package:flutter_data/flutter_data.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'book.freezed.dart';
part 'book.g.dart';

@freezed
@DataRepository([BookAuthorAdapter], remote: false)
class BookAuthor extends DataModel<BookAuthor> with _$BookAuthor {
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
@DataRepository([], remote: false)
class Book extends DataModel<Book> with _$Book {
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

  @DataFinder()
  Future<BookAuthor> caps(
    Object model, {
    bool? remote,
    bool? background,
    Map<String, dynamic>? params,
    Map<String, String>? headers,
    OnSuccessOne<BookAuthor>? onSuccess,
    OnErrorOne<BookAuthor>? onError,
    DataRequestLabel? label,
  }) async {
    final _model = await findOne(model, remote: remote);
    return _model!.copyWith(name: _model.name?.toUpperCase());
  }
}
