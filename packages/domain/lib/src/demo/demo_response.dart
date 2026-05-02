/// Generic API response wrapper
class DemoResponse<T> {
  final int code;
  final String message;
  final T? data;

  const DemoResponse({this.code = 0, this.message = '', this.data});

  bool get isSuccess => code == 0 || code == 200;

  factory DemoResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromData,
  ) {
    return DemoResponse(
      code: json['code'] as int? ?? 0,
      message: json['message'] as String? ?? '',
      data: json['data'] != null && fromData != null
          ? fromData(json['data'])
          : null,
    );
  }
}
