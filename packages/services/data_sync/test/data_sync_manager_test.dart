import 'package:flutter_test/flutter_test.dart';
import 'package:data_sync/data_sync.dart';

class _MockSyncable extends DataSyncable {
  final int _priority;
  final bool _shouldSucceed;
  bool wasCalled = false;
  _MockSyncable(this._priority, this._shouldSucceed);

  @override
  int get priority => _priority;

  @override
  Future<bool> sync() async {
    wasCalled = true;
    return _shouldSucceed;
  }
}

void main() {
  group('DataSyncManager', () {
    late DataSyncManager manager;

    setUp(() {
      manager = DataSyncManager();
    });

    test('sync with no registrations returns (0,0)', () async {
      final result = await manager.sync();
      expect(result.success, 0);
      expect(result.failed, 0);
    });

    test('sync calls all registered syncables', () async {
      final a = _MockSyncable(1, true);
      final b = _MockSyncable(2, true);
      manager.register(a);
      manager.register(b);
      final result = await manager.sync();
      expect(a.wasCalled, true);
      expect(b.wasCalled, true);
      expect(result.success, 2);
      expect(result.failed, 0);
    });

    test('sync counts failures correctly', () async {
      manager.register(_MockSyncable(1, true));
      manager.register(_MockSyncable(2, false));
      final result = await manager.sync();
      expect(result.success, 1);
      expect(result.failed, 1);
    });

    test('sync continues after exception', () async {
      manager.register(_ThrowingSyncable(1));
      final b = _MockSyncable(2, true);
      manager.register(b);
      final result = await manager.sync();
      expect(b.wasCalled, true);
      expect(result.failed, 1);
    });

    test('clear removes all registrations', () async {
      manager.register(_MockSyncable(1, true));
      manager.clear();
      final result = await manager.sync();
      expect(result.success, 0);
    });
  });
}

class _ThrowingSyncable extends DataSyncable {
  _ThrowingSyncable(this._priority);
  final int _priority;
  @override
  int get priority => _priority;
  @override
  Future<bool> sync() async => throw Exception('simulated error');
}
