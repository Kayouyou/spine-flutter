/// 可同步数据源接口
abstract class DataSyncable {
  int get priority;
  Future<bool> sync();
}
