import 'package:get_it/get_it.dart';
import 'package:data_sync/src/manager.dart';
import 'package:data_sync/src/startup_syncable.dart';

void setupDataSync(GetIt sl) {
  final manager = DataSyncManager()..register(StartupSyncable());
  sl.registerSingleton<DataSyncManager>(manager);
}