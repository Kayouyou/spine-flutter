import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  static String AgreePrivacyAndProtocol = 'agree_privacy_and_protocol';

  static String AgreePrivacyDriverLicense = 'agree_privacy_driver_license';
  static String AgreeLocationDeviceAgreement =
      'agree_location_device_agreement';

  // 首次启动引导页完成标记
  static String FirstLaunchOnboardingCompleted =
      'first_launch_onboarding_completed';

  static String LoginByUserName = 'login_by_user_name';
  static String LoginByWeChat = 'login_by_we_chat';
  static String RegisterByUserName = 'register_by_user_name';

  // 位置信息
  static String LocationCityName = 'location_city_name';
  static String LocationCityCode = 'location_city_code';

  // 行程信息选中车辆ID集合
  static String TripInfoSelectedCarIds = 'trip_info_car_ids';

  // 行程信息选中日期
  static String TripInfoSelectedDate = 'trip_info_date';

  // 行程统计选中车辆ID集合
  static String TripStatisticSelectedCarIds = 'trip_statistic_car_ids';

  // 行程统计选中日期
  static String TripStatisticSelectedDate = 'trip_statistic_date';

  // 行程统计选中年份
  static String TripStatisticSelectedYear = 'trip_statistic_year';

  // 行程统计选中月份
  static String TripStatisticSelectedMonth = 'trip_statistic_month';

  // 行程统计选中年或月
  static String TripStatisticSelectedYearOrMonth =
      'trip_statistic_year_or_month';

  // 行程统计月度选中的年月值
  static String TripStatisticSelectedYearMonth = 'trip_statistic_year_month';

  // 围栏统计选中日期
  static String FenceStatisticSelectedYear = 'fence_statistic_selected_year';
  // 围栏统计月度选中的年月值
  static String FenceStatisticSelectedYearMonth = 'fence_statistic_year_month';
  // 围栏统计选中月份
  static String FenceStatisticSelectedMonth = 'fence_statistic_selected_month';
  // 围栏统计是否为月度模式
  static String FenceStatisticIsMonth = 'fence_statistic_is_month';

  // 围栏统计选中年或月
  static String FenceStatisticSelectedYearOrMonth =
      'fence_statistic_year_or_month';

  // 综合统计选中车辆ID集合
  // 综合统计选中车辆ID集合
  static String IncomeExpenseStatisticSelectedCarIds =
      'income_expense_statistic_car_ids';

  // 综合统计选中日期-年份
  static String IncomeExpenseStatisticSelectedYear =
      'income_expense_statistic_year';

  // 能耗统计选中车辆ID集合
  static String EnergyConsumptionStatisticSelectedCarIds =
      'energy_consumption_statistic_car_ids';

  // 能耗统计选中日期
  static String EnergyConsumptionStatisticSelectedDate =
      'energy_consumption_statistic_date';

  // 位置当前聚焦的设备ID
  static String LocationFocusDeviceId = 'mine_location_focus_device_id';

  // 位置当前选中的设备ID集合
  static String LocationSelectedDeviceIds = 'mine_location_selected_device_ids';

  // 位置当前实时距离pannel的 展开状态 isExpand
  static String LocationIsExpand = 'mine_location_is_expand';

  // 位置当前实时距离pannel的连线状态
  static String LocationIsLine = 'mine_location_is_line';

  //  circle intro
  //  rectangle intro
  //  polygon intro
  static String CircleIntro = 'circle_intro';
  static String RectangleIntro = 'rectangle_intro';
  static String PolygonIntro = 'polygon_intro';

  // 围栏记录选中车辆ID集合
  static String FenceRecordSelectedCarIds = 'fence_record_car_ids';

  // 围栏记录选中日期
  static String FenceRecordSelectedDate = 'fence_record_date';

  // 围栏ID
  static String FenceRecordFenceIds = 'fence_record_fence_id';

  // 车辆事件输入限制
  static String CarEventInputLimit = 'car_event_input_limit';
  // 小车车速分段配置
  static String SmallCarSpeedSegmentConfig = 'small_car_speed_segment_config';
  // 货车车速分段配置
  static String TruckSpeedSegmentConfig = 'truck_speed_segment_config';
  // 摩托车车速分段配置
  static String MotorcycleSpeedSegmentConfig =
      'motorcycle_speed_segment_config';
  // 电动车车速分段配置
  static String ElectricCarSpeedSegmentConfig =
      'electric_car_speed_segment_config';
  // 其他种类速度分段配置（人或其他动物）
  static String OtherSpeedSegmentConfig = 'other_speed_segment_config';

  // 广告配置版本号
  static String AdConfigVersion = 'ad_config_version';

  // 提醒项目选中车辆ID集合
  static String ReminderSelectedCarIds = 'reminder_car_ids';

  // 提醒项目选中状态ID集合
  static String ReminderSelectedStatusIds = 'reminder_status_ids';

  // 提醒项目信息选中日期
  static String ReminderSelectedDate = 'reminder_date';

  // 提醒项目选中状态
  static String ReminderSelectedStatus = 'reminder_status';

  // 列表数据模式
  static String CarListDataMode = 'car_list_data_mode';

  Future<void> setString(String key, String value) async {
    final prefs = await _prefs;
    await prefs.setString(key, value);
  }

  Future<String?> getString(String key) async {
    final prefs = await _prefs;
    return prefs.getString(key);
  }

  Future<void> setInt(String key, int value) async {
    final prefs = await _prefs;
    await prefs.setInt(key, value);
  }

  Future<int?> getInt(String key) async {
    final prefs = await _prefs;
    return prefs.getInt(key);
  }

  Future<void> setBool(String key, bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(key, value);
  }

  Future<bool?> getBool(String key) async {
    final prefs = await _prefs;
    return prefs.getBool(key) ?? false;
  }

  Future<void> saveMap(Map<String, dynamic> map, String prefKey) async {
    final prefs = await SharedPreferences.getInstance();
    String jsonString = jsonEncode(map);
    await prefs.setString(prefKey, jsonString);
  }

  Future<Map<String, dynamic>> readMapFromSharedPreferences(
      String prefKey) async {
    final prefs = await SharedPreferences.getInstance();
    String? jsonString = prefs.getString(prefKey);
    if (jsonString != null) {
      return jsonDecode(jsonString);
    } else {
      return {}; // 如果没有找到或为空，返回一个空Map
    }
  }

  Future<void> saveListMap(List<dynamic> dataList, String key) async {
    final jsonString =
        jsonEncode(dataList); // 将List<Map<String, dynamic>>转换为JSON字符串
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonString); // 保存JSON字符串到SharedPreferences
  }

  Future<List<dynamic>> readListMap(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(key); // 从SharedPreferences读取JSON字符串
    return jsonString != null
        ? jsonDecode(jsonString) as List<dynamic>
        : []; // 将JSON字符串转换回List<Map<String, dynamic>>
  }

  /// 删除指定key的数据
  Future<bool> remove(String key) async {
    final prefs = await _prefs;
    return await prefs.remove(key);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();

    // 保存需要保留的值，使用更安全的方式
    final privacyProtocol = await prefs.getBool(AgreePrivacyAndProtocol);
    final driverLicense = await prefs.getBool(AgreePrivacyDriverLicense);
    final firstLaunchOnboardingCompleted =
        await prefs.getBool(FirstLaunchOnboardingCompleted);

    // 添加调试日志
    debugPrint(
        'PreferencesService.clear() - 保存的值: privacy=$privacyProtocol, driver=$driverLicense, onboarding=$firstLaunchOnboardingCompleted');

    // 清除所有数据
    await prefs.clear();

    // 恢复需要保留的值 - 使用更严格的条件判断
    if (privacyProtocol == true) {
      // 明确检查是否为true
      await prefs.setBool(AgreePrivacyAndProtocol, true);
      debugPrint('PreferencesService.clear() - 已恢复AgreePrivacyAndProtocol为true');
    } else {
      debugPrint(
          'PreferencesService.clear() - AgreePrivacyAndProtocol未恢复，原值为: $privacyProtocol');
    }

    if (driverLicense == true) {
      await prefs.setBool(AgreePrivacyDriverLicense, true);
      debugPrint('PreferencesService.clear() - 已恢复AgreePrivacyDriverLicense为true');
    }

    if (firstLaunchOnboardingCompleted == true) {
      await prefs.setBool(FirstLaunchOnboardingCompleted, true);
      debugPrint(
          'PreferencesService.clear() - 已恢复FirstLaunchOnboardingCompleted为true');
    }
  }

  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    // 清除所有数据
    await prefs.clear();
  }
}
