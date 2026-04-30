import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../http/http_constant.dart';
import '../http/http_method.dart';

///基础请求
abstract class BaseRequest {
  // curl -X GET "http://api.devio.org/uapi/test/test?requestPrams=11" -H "accept: */*"
  // curl -X GET "https://api.devio.org/uapi/test/test/1
  var pathParams;
  var useHttps = HttpConstant.IsRelease;

  String authority() {
    return HttpConstant.Http_Host;
  }

  HttpMethod httpMethod();

  String path();

  CancelToken cancelToken() {
    return CancelToken();
  }

  String url() {
    Uri uri;
    var pathStr = path();
    //http和https切换，特殊处理下载！
    if (httpMethod() == HttpMethod.DOWNLOAD) {
      return pathStr;
    } else {
      //拼接path参数
      if (pathParams != null) {
        if (path().endsWith('/')) {
          pathStr = '${path()}$pathParams';
        } else {
          pathStr = '${path()}/$pathParams';
        }
      }

      if (httpMethod() == HttpMethod.GET) {
        if (params.keys.length != 0) {
          if (useHttps) {
            uri = Uri.https(authority(), pathStr, params);
          } else {
            uri = Uri.http(authority(), pathStr, params);
          }
        } else {
          if (useHttps) {
            uri = Uri.https(authority(), pathStr);
          } else {
            uri = Uri.http(authority(), pathStr);
          }
        }
      } else {
        if (useHttps) {
          uri = Uri.https(authority(), pathStr);
        } else {
          uri = Uri.http(authority(), pathStr);
        }
      }
    }
    return uri.toString();
  }

  bool needLogin();

  Map<String, dynamic> params = Map();

  ///添加参数
  BaseRequest add(String k, Object v) {
    params[k] = v;
    return this;
  }

  Map<String, dynamic> header = {
    'Content-type': 'application/json',
    // 'accessKeyId': HttpConstant.AccessKeyId,
    'version': HttpConstant.Version,
    'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
    'signType': HttpConstant.SignType, //signType.string,
    'nonce': Uuid().v4(),
    'token': '',
    'sign': '',
  };
  // var uuid = Uuid(options: {
  // /   'grng': UuidUtil.mathRNG
  // / })
  ///添加header
  BaseRequest addHeader(String k, Object v) {
    header[k] = v.toString();
    return this;
  }
}

extension ExtenionBaseRequest on BaseRequest {
  ///添加参数
  void addIfNotNull(String key, dynamic value) {
    if (value != null) {
      this.add(key, value);
    }
  }
}
