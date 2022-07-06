// ignore_for_file: invalid_annotation_target

import 'package:flutter_data/flutter_data.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'house.dart';
import 'person.dart';

part 'book.freezed.dart';
part 'book.g.dart';

@freezed
@DataRepository([BookAuthorAdapter], remote: false, typeId: 8)
class BookAuthor extends DataModel<BookAuthor> with _$BookAuthor {
  BookAuthor._();
  factory BookAuthor({
    required int id,
    String? name,
    required HasMany<Book> books,
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
    @JsonKey(name: 'original_author_id') BelongsTo<BookAuthor>? originalAuthor,
    BelongsTo<House>? house,
    required HasMany<Person> ardentSupporters,
  }) = _Book;
  factory Book.fromJson(Map<String, dynamic> json) => _$BookFromJson(json);
}

mixin BookAuthorAdapter on RemoteAdapter<BookAuthor> {
  @override
  String get type => 'writers';

  @DataFinder()
  Future<BookAuthor> caps(
    Object id, {
    bool? remote,
    bool? background,
    Map<String, dynamic>? params,
    Map<String, String>? headers,
    OnSuccessOne<BookAuthor>? onSuccess,
    OnErrorOne<BookAuthor>? onError,
    DataRequestLabel? label,
  }) async {
    final model = await findOne(id, remote: remote);
    return model!.copyWith(name: model.name?.toUpperCase()).saveLocal();
  }
}
