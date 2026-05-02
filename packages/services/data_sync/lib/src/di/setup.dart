import 'package:get_it/get_it.dart';
import 'package:data_sync/src/manager.dart';

void setupDataSync(GetIt sl) {
  sl.registerSingleton<DataSyncManager>(DataSyncManager());
}