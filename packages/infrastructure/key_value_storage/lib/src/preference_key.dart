/// Storage value type enum
enum StorageValueType {
  string,
  int,
  bool,
}

/// Preference key group for better organization
enum PreferenceKeyGroup {
  auth,
  location,
  trip,
  fence,
  privacy,
  onboarding,
  reminder,
  car,
  shape,
  misc,
}

/// SharedPreferences storage key enum with type information and group
enum PreferenceKey {
  // Privacy group
  agreePrivacyAndProtocol('agree_privacy_and_protocol', StorageValueType.bool, PreferenceKeyGroup.privacy),
  agreePrivacyDriverLicense('agree_privacy_driver_license', StorageValueType.bool, PreferenceKeyGroup.privacy),
  agreeLocationDeviceAgreement('agree_location_device_agreement', StorageValueType.bool, PreferenceKeyGroup.privacy),
  
  // Onboarding group
  firstLaunchOnboardingCompleted('first_launch_onboarding_completed', StorageValueType.bool, PreferenceKeyGroup.onboarding),
  
  // Auth group
  loginByUserName('login_by_user_name', StorageValueType.bool, PreferenceKeyGroup.auth),
  loginByWeChat('login_by_we_chat', StorageValueType.bool, PreferenceKeyGroup.auth),
  registerByUserName('register_by_user_name', StorageValueType.bool, PreferenceKeyGroup.auth),
  authToken('auth_token', StorageValueType.string, PreferenceKeyGroup.auth),
  authUserId('auth_user_id', StorageValueType.string, PreferenceKeyGroup.auth),
  
  // Location group
  locationCityName('location_city_name', StorageValueType.string, PreferenceKeyGroup.location),
  locationCityCode('location_city_code', StorageValueType.string, PreferenceKeyGroup.location),
  locationFocusDeviceId('mine_location_focus_device_id', StorageValueType.string, PreferenceKeyGroup.location),
  locationSelectedDeviceIds('mine_location_selected_device_ids', StorageValueType.string, PreferenceKeyGroup.location),
  locationIsExpand('mine_location_is_expand', StorageValueType.bool, PreferenceKeyGroup.location),
  locationIsLine('mine_location_is_line', StorageValueType.bool, PreferenceKeyGroup.location),
  
  // Trip group
  tripInfoSelectedCarIds('trip_info_car_ids', StorageValueType.string, PreferenceKeyGroup.trip),
  tripInfoSelectedDate('trip_info_date', StorageValueType.string, PreferenceKeyGroup.trip),
  tripStatisticSelectedCarIds('trip_statistic_car_ids', StorageValueType.string, PreferenceKeyGroup.trip),
  tripStatisticSelectedDate('trip_statistic_date', StorageValueType.string, PreferenceKeyGroup.trip),
  tripStatisticSelectedYear('trip_statistic_year', StorageValueType.string, PreferenceKeyGroup.trip),
  tripStatisticSelectedMonth('trip_statistic_month', StorageValueType.string, PreferenceKeyGroup.trip),
  tripStatisticSelectedYearOrMonth('trip_statistic_year_or_month', StorageValueType.string, PreferenceKeyGroup.trip),
  tripStatisticSelectedYearMonth('trip_statistic_year_month', StorageValueType.string, PreferenceKeyGroup.trip),
  
  // Fence group
  fenceStatisticSelectedYear('fence_statistic_selected_year', StorageValueType.string, PreferenceKeyGroup.fence),
  fenceStatisticSelectedYearMonth('fence_statistic_year_month', StorageValueType.string, PreferenceKeyGroup.fence),
  fenceStatisticSelectedMonth('fence_statistic_selected_month', StorageValueType.string, PreferenceKeyGroup.fence),
  fenceStatisticIsMonth('fence_statistic_is_month', StorageValueType.bool, PreferenceKeyGroup.fence),
  fenceStatisticSelectedYearOrMonth('fence_statistic_year_or_month', StorageValueType.string, PreferenceKeyGroup.fence),
  fenceRecordSelectedCarIds('fence_record_car_ids', StorageValueType.string, PreferenceKeyGroup.fence),
  fenceRecordSelectedDate('fence_record_date', StorageValueType.string, PreferenceKeyGroup.fence),
  fenceRecordFenceIds('fence_record_fence_id', StorageValueType.string, PreferenceKeyGroup.fence),
  
  // Statistics group
  incomeExpenseStatisticSelectedCarIds('income_expense_statistic_car_ids', StorageValueType.string, PreferenceKeyGroup.trip),
  incomeExpenseStatisticSelectedYear('income_expense_statistic_year', StorageValueType.string, PreferenceKeyGroup.trip),
  energyConsumptionStatisticSelectedCarIds('energy_consumption_statistic_car_ids', StorageValueType.string, PreferenceKeyGroup.trip),
  energyConsumptionStatisticSelectedDate('energy_consumption_statistic_date', StorageValueType.string, PreferenceKeyGroup.trip),
  
  // Shape group
  circleIntro('circle_intro', StorageValueType.bool, PreferenceKeyGroup.shape),
  rectangleIntro('rectangle_intro', StorageValueType.bool, PreferenceKeyGroup.shape),
  polygonIntro('polygon_intro', StorageValueType.bool, PreferenceKeyGroup.shape),
  
  // Car group
  carEventInputLimit('car_event_input_limit', StorageValueType.int, PreferenceKeyGroup.car),
  smallCarSpeedSegmentConfig('small_car_speed_segment_config', StorageValueType.string, PreferenceKeyGroup.car),
  truckSpeedSegmentConfig('truck_speed_segment_config', StorageValueType.string, PreferenceKeyGroup.car),
  motorcycleSpeedSegmentConfig('motorcycle_speed_segment_config', StorageValueType.string, PreferenceKeyGroup.car),
  electricCarSpeedSegmentConfig('electric_car_speed_segment_config', StorageValueType.string, PreferenceKeyGroup.car),
  otherSpeedSegmentConfig('other_speed_segment_config', StorageValueType.string, PreferenceKeyGroup.car),
  carListDataMode('car_list_data_mode', StorageValueType.string, PreferenceKeyGroup.car),
  
  // Reminder group
  reminderSelectedCarIds('reminder_car_ids', StorageValueType.string, PreferenceKeyGroup.reminder),
  reminderSelectedStatusIds('reminder_status_ids', StorageValueType.string, PreferenceKeyGroup.reminder),
  reminderSelectedDate('reminder_date', StorageValueType.string, PreferenceKeyGroup.reminder),
  reminderSelectedStatus('reminder_status', StorageValueType.string, PreferenceKeyGroup.reminder),
  
  // Misc group
  adConfigVersion('ad_config_version', StorageValueType.int, PreferenceKeyGroup.misc),
  ;

  final String rawKey;
  final StorageValueType valueType;
  final PreferenceKeyGroup group;
  
  const PreferenceKey(this.rawKey, this.valueType, this.group);
  
  /// Get all keys in a specific group
  static List<PreferenceKey> keysInGroup(PreferenceKeyGroup group) {
    return PreferenceKey.values.where((key) => key.group == group).toList();
  }
}
