import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/core/middleware/request_context.dart';

void main() {
  group('RequestContext', () {
    tearDown(RequestContext.clear);

    test('currentTag returns null by default', () {
      expect(RequestContext.currentTag, isNull);
    });

    test('setTag sets currentTag', () {
      RequestContext.setTag('/home');
      expect(RequestContext.currentTag, '/home');
    });

    test('setTag overwrites previous tag', () {
      RequestContext.setTag('/home');
      RequestContext.setTag('/detail/:id');
      expect(RequestContext.currentTag, '/detail/:id');
    });

    test('clear resets currentTag to null', () {
      RequestContext.setTag('/home');
      RequestContext.clear();
      expect(RequestContext.currentTag, isNull);
    });

    test('clear is idempotent', () {
      RequestContext.clear();
      RequestContext.clear();
      expect(RequestContext.currentTag, isNull);
    });
  });
}
