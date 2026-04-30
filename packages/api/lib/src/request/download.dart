import 'dart:io';
import '../http/http_method.dart';
import 'base_request.dart';

class DownLoadRequest extends BaseRequest {
  final String downLoadUrl;
  final File savePath;
  // VoidCallback progress;
  DownLoadRequest({required this.downLoadUrl, required this.savePath});

  @override
  HttpMethod httpMethod() {
    return HttpMethod.DOWNLOAD;
  }

  @override
  bool needLogin() {
    return false;
  }

  @override
  String path() {
    return downLoadUrl;
  }
}
