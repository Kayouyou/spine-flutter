import 'package:flutter/foundation.dart';
import 'data_syncable.dart';

class DataSyncManager {
  final List<DataSyncable> _syncables = [];

  void register(DataSyncable syncable) {
    _syncables.add(syncable);
    _syncables.sort((a, b) => a.priority.compareTo(b.priority));
  }

  Future<({int success, int failed})> sync() async {
    if (kDebugMode) {
      debugPrint('DataSyncManager: starting sync (${_syncables.length} tasks)');
    }

    int success = 0;
    int failed = 0;

    for (final syncable in _syncables) {
      try {
        final ok = await syncable.sync();
        if (ok) {
          success++;
        } else {
          failed++;
        }
      } catch (e) {
        failed++;
        if (kDebugMode) {
          debugPrint('DataSyncManager: sync error: $e');
        }
      }
    }

    if (kDebugMode) {
      debugPrint('DataSyncManager: done (success: $success, failed: $failed)');
    }
    return (success: success, failed: failed);
  }

  void clear() => _syncables.clear();
}
