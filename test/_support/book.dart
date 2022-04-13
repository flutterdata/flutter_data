// ignore_for_file: invalid_annotation_target

import 'package:flutter_data/flutter_data.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'setup.dart';

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
@DataRepository([], remote: false)
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
      super.strategies.add(finderOne: censor, name: 'censor');

  DataFinderOne<BookAuthor> get censor => (
        Object model, {
        bool? remote,
        Map<String, dynamic>? params,
        Map<String, String>? headers,
        OnSuccess<BookAuthor?>? onSuccess,
        OnError<BookAuthor?>? onError,
      }) async {
        final _model = await findOne(model, remote: remote);
        if (_model?.books?.toList().isNotEmpty ?? false) {
          // save a relationship of
          await _model!.books!.first.save();
        }
        await oneMs();
        return _model!.copyWith(name: '#&(@*@&@!*(!').was(_model);
        // return BookAuthor(id: model as int, name: '#&(@*@&@!*(!').init(read);
      };
}
