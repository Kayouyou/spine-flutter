import 'package:dio/dio.dart';

class ErrorInterceptor extends Interceptor {
  ErrorInterceptor({
    required void Function(
      Object error,
      StackTrace? stack, {
      Map<String, dynamic> context,
    }) onError,
  }) : _onError = onError;

  final void Function(
    Object error,
    StackTrace? stack, {
    Map<String, dynamic> context,
  }) _onError;
}
