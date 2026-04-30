enum ApplicationTypes {
  // 驾驶证
  driverLicense, // drvlic
  // 车辆位置
  vehicleLocation, // loc
  // 行程统计
  tripStatistics, // trvst
  // 行程信息
  tripInfo, // trv
  // 车辆轨迹
  vehicleTrack, // track
  // 综合收支
  comprehensiveIncome, // fina
  // 综合能耗
  comprehensiveEnergy, // energ
  // 电子围栏
  electronicFence, // fence
  // 围栏记录
  fenceRecord, // fence record
  // 围栏统计
  fenceStatistics, // fence statistics
  // 地址本
  addressBook, // adbk
  // 备忘录
  memo, // ntc
  // 记事件
  event, // evt
  // 加油站
  gasStation, // gas
  // 充电站
  chargingStation, // charge
  // 排行榜
  ranking, // ranking
  // 能耗计算器
  powerConsumptionCalculator, // pwr_calc
}

/// 枚举映射
class EnumMapper {
  static final Map<String, ApplicationTypes> _byShortName = {
    'drvlic': ApplicationTypes.driverLicense,
    'loc': ApplicationTypes.vehicleLocation,
    'trvst': ApplicationTypes.tripStatistics,
    'trv': ApplicationTypes.tripInfo,
    'track': ApplicationTypes.vehicleTrack,
    'fina': ApplicationTypes.comprehensiveIncome,
    'energ': ApplicationTypes.comprehensiveEnergy,
    'adbk': ApplicationTypes.addressBook,
    'ntc': ApplicationTypes.memo,
    'fence': ApplicationTypes.electronicFence,
    'fence_rcd': ApplicationTypes.fenceRecord,
    'fence_sts': ApplicationTypes.fenceStatistics,
    'events': ApplicationTypes.event,
    'gas': ApplicationTypes.gasStation,
    'charge': ApplicationTypes.chargingStation,
    'ranking': ApplicationTypes.ranking,
    'ml_rank': ApplicationTypes.ranking, // 添加ml_rank映射到ranking
    'ecp_calc': ApplicationTypes.powerConsumptionCalculator,
  };

  static ApplicationTypes? applicationTypeFromShortIdentifier(
      String shortName) {
    return _byShortName[shortName];
  }
}
