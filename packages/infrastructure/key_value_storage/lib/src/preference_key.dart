/// Storage value type enum
enum StorageValueType {
  string,
  int,
  bool,
}

/// SharedPreferences storage key enum with type information
enum PreferenceKey {
  agreePrivacyAndProtocol('agree_privacy_and_protocol', StorageValueType.bool),
  agreePrivacyDriverLicense('agree_privacy_driver_license', StorageValueType.bool),
  agreeLocationDeviceAgreement('agree_location_device_agreement', StorageValueType.bool),
  firstLaunchOnboardingCompleted('first_launch_onboarding_completed', StorageValueType.bool),
  loginByUserName('login_by_user_name', StorageValueType.bool),
  loginByWeChat('login_by_we_chat', StorageValueType.bool),
  registerByUserName('register_by_user_name', StorageValueType.bool),
  locationCityName('location_city_name', StorageValueType.string),
  locationCityCode('location_city_code', StorageValueType.string),
  locationFocusDeviceId('mine_location_focus_device_id', StorageValueType.string),
  locationSelectedDeviceIds('mine_location_selected_device_ids', StorageValueType.string),
  locationIsExpand('mine_location_is_expand', StorageValueType.bool),
  locationIsLine('mine_location_is_line', StorageValueType.bool),
  tripInfoSelectedCarIds('trip_info_car_ids', StorageValueType.string),
  tripInfoSelectedDate('trip_info_date', StorageValueType.string),
  tripStatisticSelectedCarIds('trip_statistic_car_ids', StorageValueType.string),
  tripStatisticSelectedDate('trip_statistic_date', StorageValueType.string),
  tripStatisticSelectedYear('trip_statistic_year', StorageValueType.string),
  tripStatisticSelectedMonth('trip_statistic_month', StorageValueType.string),
  tripStatisticSelectedYearOrMonth('trip_statistic_year_or_month', StorageValueType.string),
  tripStatisticSelectedYearMonth('trip_statistic_year_month', StorageValueType.string),
  fenceStatisticSelectedYear('fence_statistic_selected_year', StorageValueType.string),
  fenceStatisticSelectedYearMonth('fence_statistic_year_month', StorageValueType.string),
  fenceStatisticSelectedMonth('fence_statistic_selected_month', StorageValueType.string),
  fenceStatisticIsMonth('fence_statistic_is_month', StorageValueType.bool),
  fenceStatisticSelectedYearOrMonth('fence_statistic_year_or_month', StorageValueType.string),
  fenceRecordSelectedCarIds('fence_record_car_ids', StorageValueType.string),
  fenceRecordSelectedDate('fence_record_date', StorageValueType.string),
  fenceRecordFenceIds('fence_record_fence_id', StorageValueType.string),
  incomeExpenseStatisticSelectedCarIds('income_expense_statistic_car_ids', StorageValueType.string),
  incomeExpenseStatisticSelectedYear('income_expense_statistic_year', StorageValueType.string),
  energyConsumptionStatisticSelectedCarIds('energy_consumption_statistic_car_ids', StorageValueType.string),
  energyConsumptionStatisticSelectedDate('energy_consumption_statistic_date', StorageValueType.string),
  circleIntro('circle_intro', StorageValueType.bool),
  rectangleIntro('rectangle_intro', StorageValueType.bool),
  polygonIntro('polygon_intro', StorageValueType.bool),
  carEventInputLimit('car_event_input_limit', StorageValueType.int),
  smallCarSpeedSegmentConfig('small_car_speed_segment_config', StorageValueType.string),
  truckSpeedSegmentConfig('truck_speed_segment_config', StorageValueType.string),
  motorcycleSpeedSegmentConfig('motorcycle_speed_segment_config', StorageValueType.string),
  electricCarSpeedSegmentConfig('electric_car_speed_segment_config', StorageValueType.string),
  otherSpeedSegmentConfig('other_speed_segment_config', StorageValueType.string),
  adConfigVersion('ad_config_version', StorageValueType.int),
  reminderSelectedCarIds('reminder_car_ids', StorageValueType.string),
  reminderSelectedStatusIds('reminder_status_ids', StorageValueType.string),
  reminderSelectedDate('reminder_date', StorageValueType.string),
  reminderSelectedStatus('reminder_status', StorageValueType.string),
  carListDataMode('car_list_data_mode', StorageValueType.string),

  authToken('auth_token', StorageValueType.string),
  authUserId('auth_user_id', StorageValueType.string),
  ;

  final String rawKey;
  final StorageValueType valueType;
  const PreferenceKey(this.rawKey, this.valueType);
}
