/// 领域层统一返回类型 [Result<T, E>]
///
/// 使用 sealed class 实现类似 Rust 的 Result 模式：
///
/// ```dart
/// Result<User, DomainException> fetchUser(int id) async {
///   try {
///     final user = await api.getUser(id);
///     return Result.success(user);
///   } on DomainException catch (e) {
///     return Result.failure(e);
///   }
/// }
///
/// // 使用方通过 when 穷尽匹配：
/// final result = await fetchUser(1);
/// result.when(
///   success: (user) => print(user.name),
///   failure: (error) => showError(error.message),
/// );
/// ```
sealed class Result<T, E extends Exception> {
  const Result();

  /// 创建成功结果
  static Result<T, E> success<T, E extends Exception>(T data) => Success<T, E>(data);

  /// 创建失败结果
  static Result<T, E> failure<T, E extends Exception>(E error) => Failure<T, E>(error);

  /// 根据结果类型执行回调（穷尽匹配）
  R when<R>({
    required R Function(T data) success,
    required R Function(E error) failure,
  });

  /// 是否为成功结果
  bool get isSuccess;

  /// 是否为失败结果
  bool get isFailure;

  /// 将成功值转换为另一种类型
  ///
  /// 如果是 [Failure]，错误原样传递
  Result<R, E> map<R>(R Function(T data) transform);

  /// 将错误值转换为另一种错误类型
  ///
  /// 如果是 [Success]，值原样传递
  Result<T, R> mapError<R extends Exception>(R Function(E error) transform);

  /// 返回数据值，如果是 [Failure] 则抛出异常
  T get dataOrThrow {
    if (this is Success<T, E>) {
      return (this as Success<T, E>).data;
    }
    throw (this as Failure<T, E>).error;
  }

  /// 返回错误值，如果是 [Success] 则抛出 StateError
  E get errorOrThrow {
    if (this is Failure<T, E>) {
      return (this as Failure<T, E>).error;
    }
    throw StateError('Result 是 Success，不是 Failure');
  }

  /// 返回数据值，如果是 [Failure] 则返回默认值
  T getOrElse(T defaultValue) {
    if (this is Success<T, E>) {
      return (this as Success<T, E>).data;
    }
    return defaultValue;
  }
}

/// [Result] 的成功变体，包装成功值
class Success<T, E extends Exception> extends Result<T, E> {
  /// 成功值
  final T data;

  const Success(this.data);

  @override
  R when<R>({
    required R Function(T data) success,
    required R Function(E error) failure,
  }) {
    return success(data);
  }

  @override
  bool get isSuccess => true;

  @override
  bool get isFailure => false;

  @override
  Result<R, E> map<R>(R Function(T data) transform) {
    return Success(transform(data));
  }

  @override
  Result<T, R> mapError<R extends Exception>(R Function(E error) transform) {
    // 成功状态，忽略错误转换，直接传递
    return this as Result<T, R>;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T, E> &&
          runtimeType == other.runtimeType &&
          data == other.data;

  @override
  int get hashCode => data.hashCode;

  @override
  String toString() => 'Success($data)';
}

/// [Result] 的失败变体，包装一个异常
class Failure<T, E extends Exception> extends Result<T, E> {
  /// 导致失败的异常
  final E error;

  const Failure(this.error);

  @override
  R when<R>({
    required R Function(T data) success,
    required R Function(E error) failure,
  }) {
    return failure(error);
  }

  @override
  bool get isSuccess => false;

  @override
  bool get isFailure => true;

  @override
  Result<R, E> map<R>(R Function(T data) transform) {
    // 失败状态，忽略数据转换，直接传递
    return this as Result<R, E>;
  }

  @override
  Result<T, R> mapError<R extends Exception>(R Function(E error) transform) {
    return Failure(transform(error));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure<T, E> &&
          runtimeType == other.runtimeType &&
          error == other.error;

  @override
  int get hashCode => error.hashCode;

  @override
  String toString() => 'Failure($error)';
}
