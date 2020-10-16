// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies

part of data_state;

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
class _$DataStateTearOff {
  const _$DataStateTearOff();

// ignore: unused_element
  _DataState<T> call<T>(@nullable T model,
      {bool isLoading = false, Object exception, StackTrace stackTrace}) {
    return _DataState<T>(
      model,
      isLoading: isLoading,
      exception: exception,
      stackTrace: stackTrace,
    );
  }
}

/// @nodoc
// ignore: unused_element
const $DataState = _$DataStateTearOff();

/// @nodoc
mixin _$DataState<T> {
  @nullable
  T get model;
  bool get isLoading;
  Object get exception;
  StackTrace get stackTrace;

  $DataStateCopyWith<T, DataState<T>> get copyWith;
}

/// @nodoc
abstract class $DataStateCopyWith<T, $Res> {
  factory $DataStateCopyWith(
          DataState<T> value, $Res Function(DataState<T>) then) =
      _$DataStateCopyWithImpl<T, $Res>;
  $Res call(
      {@nullable T model,
      bool isLoading,
      Object exception,
      StackTrace stackTrace});
}

/// @nodoc
class _$DataStateCopyWithImpl<T, $Res> implements $DataStateCopyWith<T, $Res> {
  _$DataStateCopyWithImpl(this._value, this._then);

  final DataState<T> _value;
  // ignore: unused_field
  final $Res Function(DataState<T>) _then;

  @override
  $Res call({
    Object model = freezed,
    Object isLoading = freezed,
    Object exception = freezed,
    Object stackTrace = freezed,
  }) {
    return _then(_value.copyWith(
      model: model == freezed ? _value.model : model as T,
      isLoading: isLoading == freezed ? _value.isLoading : isLoading as bool,
      exception: exception == freezed ? _value.exception : exception,
      stackTrace:
          stackTrace == freezed ? _value.stackTrace : stackTrace as StackTrace,
    ));
  }
}

/// @nodoc
abstract class _$DataStateCopyWith<T, $Res>
    implements $DataStateCopyWith<T, $Res> {
  factory _$DataStateCopyWith(
          _DataState<T> value, $Res Function(_DataState<T>) then) =
      __$DataStateCopyWithImpl<T, $Res>;
  @override
  $Res call(
      {@nullable T model,
      bool isLoading,
      Object exception,
      StackTrace stackTrace});
}

/// @nodoc
class __$DataStateCopyWithImpl<T, $Res> extends _$DataStateCopyWithImpl<T, $Res>
    implements _$DataStateCopyWith<T, $Res> {
  __$DataStateCopyWithImpl(
      _DataState<T> _value, $Res Function(_DataState<T>) _then)
      : super(_value, (v) => _then(v as _DataState<T>));

  @override
  _DataState<T> get _value => super._value as _DataState<T>;

  @override
  $Res call({
    Object model = freezed,
    Object isLoading = freezed,
    Object exception = freezed,
    Object stackTrace = freezed,
  }) {
    return _then(_DataState<T>(
      model == freezed ? _value.model : model as T,
      isLoading: isLoading == freezed ? _value.isLoading : isLoading as bool,
      exception: exception == freezed ? _value.exception : exception,
      stackTrace:
          stackTrace == freezed ? _value.stackTrace : stackTrace as StackTrace,
    ));
  }
}

/// @nodoc
class _$_DataState<T> implements _DataState<T> {
  _$_DataState(@nullable this.model,
      {this.isLoading = false, this.exception, this.stackTrace})
      : assert(isLoading != null);

  @override
  @nullable
  final T model;
  @JsonKey(defaultValue: false)
  @override
  final bool isLoading;
  @override
  final Object exception;
  @override
  final StackTrace stackTrace;

  bool _didhasException = false;
  bool _hasException;

  @override
  bool get hasException {
    if (_didhasException == false) {
      _didhasException = true;
      _hasException = exception != null;
    }
    return _hasException;
  }

  bool _didhasModel = false;
  bool _hasModel;

  @override
  bool get hasModel {
    if (_didhasModel == false) {
      _didhasModel = true;
      _hasModel = model != null;
    }
    return _hasModel;
  }

  @override
  String toString() {
    return 'DataState<$T>(model: $model, isLoading: $isLoading, exception: $exception, stackTrace: $stackTrace, hasException: $hasException, hasModel: $hasModel)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _DataState<T> &&
            (identical(other.model, model) ||
                const DeepCollectionEquality().equals(other.model, model)) &&
            (identical(other.isLoading, isLoading) ||
                const DeepCollectionEquality()
                    .equals(other.isLoading, isLoading)) &&
            (identical(other.exception, exception) ||
                const DeepCollectionEquality()
                    .equals(other.exception, exception)) &&
            (identical(other.stackTrace, stackTrace) ||
                const DeepCollectionEquality()
                    .equals(other.stackTrace, stackTrace)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      const DeepCollectionEquality().hash(model) ^
      const DeepCollectionEquality().hash(isLoading) ^
      const DeepCollectionEquality().hash(exception) ^
      const DeepCollectionEquality().hash(stackTrace);

  @override
  _$DataStateCopyWith<T, _DataState<T>> get copyWith =>
      __$DataStateCopyWithImpl<T, _DataState<T>>(this, _$identity);
}

abstract class _DataState<T> implements DataState<T> {
  factory _DataState(@nullable T model,
      {bool isLoading,
      Object exception,
      StackTrace stackTrace}) = _$_DataState<T>;

  @override
  @nullable
  T get model;
  @override
  bool get isLoading;
  @override
  Object get exception;
  @override
  StackTrace get stackTrace;
  @override
  _$DataStateCopyWith<T, _DataState<T>> get copyWith;
}
