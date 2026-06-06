// test/unit/request_context_stack_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_flutter/core/middleware/request_context.dart';

void main() {
  setUp(() => RequestContext.clear());

  test('push 后 currentTag 是最新值', () {
    RequestContext.pushTag('outer');
    RequestContext.pushTag('inner');
    expect(RequestContext.currentTag, 'inner');
  });

  test('pop 恢复外层 tag', () {
    RequestContext.pushTag('outer');
    RequestContext.pushTag('inner');
    RequestContext.popTag();
    expect(RequestContext.currentTag, 'outer');
  });

  test('pop 到底不报错 (空栈安全)', () {
    RequestContext.pushTag('outer');
    RequestContext.popTag();
    RequestContext.popTag();
    expect(RequestContext.currentTag, isNull);
  });

  test('多层嵌套 LIFO 正确', () {
    RequestContext.pushTag('a');
    RequestContext.pushTag('b');
    RequestContext.pushTag('c');
    RequestContext.popTag();
    expect(RequestContext.currentTag, 'b');
    RequestContext.popTag();
    expect(RequestContext.currentTag, 'a');
    RequestContext.popTag();
    expect(RequestContext.currentTag, isNull);
  });
}
