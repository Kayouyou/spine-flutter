import 'package:flutter_screenutil/flutter_screenutil.dart';

abstract class FontSize {
  static const double small = 9;
  static const double medium = 11;
  static const double mediumLarge = 14;
  static const double normal = 16;
  static const double large = 18;
  static const double xLarge = 20;
  static const double xxLarge = 24;

  static const double text_placeholder = 12;

  // 使用getter方法替代静态变量，避免在ScreenUtil初始化前调用.sp
  static double get size_9 => 9.sp;
  static double get size_11 => 11.sp;
  static double get size_12 => 12.sp;
  static double get size_13 => 13.sp;
  static double get size_14 => 14.sp;
  static double get size_16 => 16.sp;
  static double get size_18 => 18.sp;
  static double get size_20 => 20.sp;
  static double get size_21 => 21.sp;
  static double get size_22 => 22.sp;
  static double get size_24 => 24.sp;
}
