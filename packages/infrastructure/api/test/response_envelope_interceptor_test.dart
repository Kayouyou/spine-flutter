import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:api/src/dio/response_envelope_interceptor.dart';
import 'package:domain/domain.dart';

/// 记录 next/resolve/reject 的轻量 fake
class _FakeResponseHandler extends ResponseInterceptorHandler {
  bool nextCalled = false;
  bool rejectCalled = false;
  Response? nextResponse;
  DioException? rejected;

  @override
  void next(Response response) {
    nextCalled = true;
    nextResponse = response;
  }

  @override
  void resolve(Response response, [bool failIfNotResolved = true]) {
    nextCalled = true;
    nextResponse = response;
  }

  @override
  void reject(DioException error, [bool failIfNotResolved = true]) {
    rejectCalled = true;
    rejected = error;
  }
}

Response _resp(Map<String, dynamic> data) => Response(
      requestOptions: RequestOptions(path: '/x'),
      data: data,
      statusCode: 200,
    );

void main() {
  group('ResponseEnvelopeInterceptor', () {
    test('code==0：解包 data 为 response.data', () {
      final i = ResponseEnvelopeInterceptor();
      final h = _FakeResponseHandler();
      final payload = {'id': '1', 'name': 'bob'};
      i.onResponse(_resp({'code': 0, 'message': 'ok', 'data': payload}), h);

      expect(h.nextCalled, isTrue);
      expect(h.rejectCalled, isFalse);
      expect(h.nextResponse!.data, payload);
    });

    test('code!=0：以 BusinessException 拒绝', () {
      final i = ResponseEnvelopeInterceptor();
      final h = _FakeResponseHandler();
      i.onResponse(_resp({'code': 4001, 'message': '余额不足', 'data': null}), h);

      expect(h.rejectCalled, isTrue);
      expect(h.nextCalled, isFalse);
      expect(h.rejected!.error, isA<BusinessException>());
      expect((h.rejected!.error as BusinessException).code, 4001);
    });

    test('code==1000102：续期码原样放行', () {
      final i = ResponseEnvelopeInterceptor();
      final h = _FakeResponseHandler();
      final env = {'code': 1000102, 'message': 'token expired', 'data': null};
      i.onResponse(_resp(env), h);

      expect(h.nextCalled, isTrue);
      expect(h.rejectCalled, isFalse);
      expect(h.nextResponse!.data, env); // 不改动、不拦截
    });

    test('裸 payload（无 code/data）：原样放行', () {
      final i = ResponseEnvelopeInterceptor();
      final h = _FakeResponseHandler();
      final raw = {'id': '1', 'name': 'bob'};
      i.onResponse(_resp(raw), h);

      expect(h.nextCalled, isTrue);
      expect(h.rejectCalled, isFalse);
      expect(h.nextResponse!.data, raw); // 不破坏既有 Retrofit 解析
    });

    test('enabled=false：完全退化为原行为', () {
      final i = ResponseEnvelopeInterceptor(enabled: false);
      final h = _FakeResponseHandler();
      final env = {'code': 4001, 'message': 'err', 'data': null};
      i.onResponse(_resp(env), h);

      expect(h.nextCalled, isTrue);
      expect(h.rejectCalled, isFalse);
    });
  });
}
