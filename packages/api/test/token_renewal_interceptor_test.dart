// import 'package:flutter_test/flutter_test.dart';
// import 'package:dio/dio.dart';
// import 'package:api/src/dio/token_renewal_interceptor.dart';
// import 'package:api/src/dio/test_token_interceptor.dart';
// import 'package:test/expect.dart';
// import 'package:test/scaffolding.dart';
//
// void main() {
//   late Dio dio;
//   late TestTokenInterceptor testInterceptor;
//   late TokenRenewalInterceptor renewalInterceptor;
//
//   setUp(() {
//     dio = Dio(BaseOptions(
//       baseUrl: 'https://example.com',
//       // 配置测试环境的超时时间
//       connectTimeout: const Duration(seconds: 5),
//       receiveTimeout: const Duration(seconds: 5),
//     ));
//
//     testInterceptor = TestTokenInterceptor();
//     renewalInterceptor = TokenRenewalInterceptor(dio);
//
//     // 添加拦截器（注意顺序）
//     dio.interceptors.addAll([
//       testInterceptor,
//       renewalInterceptor,
//     ]);
//   });
//
//   tearDown(() {
//     testInterceptor.reset();
//   });
//
//   group('Token续期测试', () {
//     test('测试单个请求的续期流程', () async {
//       testInterceptor.enableTest = true;
//
//       final response = await dio.get('/api/test');
//
//       expect(response.statusCode, 200);
//       expect(testInterceptor.requestCount, 1);
//
//       // 验证响应中包含新token
//       expect(response.data['data']['token'], contains('new_test_token'));
//     });
//
//     test('测试并发请求的续期处理', () async {
//       testInterceptor.enableTest = true;
//
//       // 同时发起3个请求
//       final futures = await Future.wait([
//         dio.get('/api/test1'),
//         dio.get('/api/test2'),
//         dio.get('/api/test3'),
//       ]);
//
//       // 验证所有请求都成功完成
//       for (final response in futures) {
//         expect(response.statusCode, 200);
//         expect(response.data['data']['token'], contains('new_test_token'));
//       }
//
//       // 验证请求计数
//       expect(testInterceptor.requestCount, 3);
//     });
//
//     test('测试请求间隔续期', () async {
//       testInterceptor.enableTest = true;
//
//       // 第一个请求
//       final response1 = await dio.get('/api/test1');
//       expect(response1.statusCode, 200);
//
//       // 等待一段时间
//       await Future.delayed(const Duration(seconds: 1));
//
//       // 第二个请求
//       final response2 = await dio.get('/api/test2');
//       expect(response2.statusCode, 200);
//
//       expect(testInterceptor.requestCount, 2);
//     });
//
//     test('测试错误处理', () async {
//       testInterceptor.enableTest = true;
//
//       // 模拟网络错误
//       dio.interceptors.add(InterceptorsWrapper(
//         onRequest: (options, handler) {
//           handler.reject(
//             DioException(
//               requestOptions: options,
//               error: '网络错误',
//             ),
//           );
//         },
//       ));
//
//       expect(
//         () => dio.get('/api/test'),
//         throwsA(isA<DioException>()),
//       );
//     });
//   });
// }
