import 'dart:io';

import 'package:component_library/component_library.dart';
import 'package:component_library/src/theme/spacing.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

const _dividerThemeData = DividerThemeData(
  space: 0,
);

// If the number of properties get too big, we can start grouping them in
// classes like Flutter does with TextTheme, ButtonTheme, etc, inside ThemeData.
abstract class OVSThemeData {
  ThemeData get materialThemeData;

  double screenMargin = Spacing.mediumLarge;

  double listSeparator = Spacing.small;

  double gridSpacing = Spacing.mediumLarge;

  // 1. 主色调
  Color get mainColor;

  Color get evColor => Color(0xff31C560);

  // 2. 用车事件主题色
  // 装备主色调
  Color get equipColor;

  String get equipIcon => 'assets/story/icon_equipment.png';

  // 加油主色调
  Color get refuelColor;

  String get refuelIcon => 'assets/story/icon_refuel.png';

  // 充电主色调
  Color get chargeColor;

  String get chargeIcon => 'assets/story/icon_charge.png';

  // 维修主色调
  Color get repairColor;

  String get repairIcon => 'assets/story/icon_repair.png';

  // 保养主色调
  Color get maintainColor;

  String get maintainIcon => 'assets/story/icon_maintain.png';

  // 保险主色调
  Color get insuranceColor;

  String get insuranceIcon => 'assets/story/icon_insurance.png';

  // 改装主色调
  Color get remodelColor;

  String get refitIcon => 'assets/story/icon_refit.png';

  // 其他主色调
  Color get eventOtherColor;

  String get expendIcon => 'assets/story/icon_Other.png';

  // 收入主色调
  Color get incomeColor;

  String get incomeIcon => 'assets/story/icon_income.png';

  // 3. 能耗信息配色
  // 加油
  Color get refuelInfoColor;

  // 里程
  Color get mileageInfoColor;

  // 经济
  Color get economyInfoColor;

  // 4. 背景色
  // 页面背景色
  Color get pageBackgroundColor;

  // 备注背景色
  Color get noteBackgroundColor;

  // 卡片背景色
  Color get cardBackgroundColor;

  // 控件背景色
  Color get widgetBackgroundColor;

  // 文字背景色
  Color get textBackgroundColor;

  // 5. 分割线
  Color get dividerColor;

  // 6. 文字色
  // 主色
  Color get mainTextColor;

  // 配色1-4
  Color get color1;

  Color get color2;

  Color get color3;

  Color get color4;

  // 主标题
  Color get mainTitleColor;

  // 副标题和正文
  Color get subTitleColor;

  // 弱文案
  Color get weakTextColor;

  // placeholder
  Color get placeholderColor;

  // 强调数字
  Color get strongNumTextColor;

  // 7. 蒙层
  Color get overlayColor;

  // 8. arrow
  Color get rightArrowColor;

  // 9 加油刻度安全颜色：比较充足
  Color get refuelSafeColor;

  // 10 充电刻度安全颜色：比较充足
  Color get chargeSafeColor;

  // 11 能源刻度背景色
  Color get energyBgColor;

  // 12 checkboxGreyBGColor
  Color get checkboxGreyBGColor => const Color(0xffE7E7E7);

  // 13 energyRateTextColor
  Color get energyRateTextColor => Color.fromARGB(255, 2, 123, 27);

  TextStyle quoteTextStyle = const TextStyle(
    fontFamily: 'Fondamento',
    package: 'component_library',
  );

  TextStyle numTextStyle = TextStyle(
      fontFamily: 'MiSans',
      color: const Color(0xff565656),
      fontSize: 17.sp,
      fontWeight: FontWeight.w500);

  TextStyle customTextStyle({
    String fontFamily = 'MiSans',
    Color color = const Color(0xff565656),
    double fontSize = 17.0,
    FontWeight fontWeight = FontWeight.w500,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
    );
  }

  // 苹方字体 导航title
  TextStyle navBarTitleStyle({
    Color color = const Color(0xff333333),
    double fontSize = 16.0,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    return TextStyle(
      fontFamily: Platform.isIOS ? 'PingFang SC' : null,
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: 0.15, // 适当的字间距
    );
  }

  // 苹方字体
  TextStyle pingFangSemiBoldTextStyle({
    Color color = const Color(0xff333333),
    double fontSize = 17.0,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    return TextStyle(
      fontFamily: Platform.isIOS ? 'PingFang SC' : null,
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
    );
  }

  TextStyle pingFangMediumTextStyle({
    Color color = const Color(0xff333333),
    double fontSize = 17.0,
    FontWeight fontWeight = FontWeight.w500,
  }) {
    return TextStyle(
      fontFamily: Platform.isIOS ? 'PingFang SC' : null,
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
    );
  }

  TextStyle pingFangRegularTextStyle({
    Color color = const Color(0xff333333),
    double fontSize = 17.0,
    FontWeight fontWeight = FontWeight.w400,
  }) {
    return TextStyle(
      fontFamily: Platform.isIOS ? 'PingFang SC' : null,
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
    );
  }

  TextStyle pingFangLightTextStyle({
    Color color = const Color(0xff333333),
    double fontSize = 17.0,
    FontWeight fontWeight = FontWeight.w200,
  }) {
    return TextStyle(
      fontFamily: Platform.isIOS ? 'PingFang SC' : null,
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
    );
  }

  TextStyle pingFangBoldTextStyle({
    Color color = const Color(0xff333333),
    double fontSize = 17.0,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    return TextStyle(
      fontFamily: Platform.isIOS ? 'PingFang SC' : null,
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
    );
  }
}

class LightOVSThemeData extends OVSThemeData {
  @override
  ThemeData get materialThemeData => ThemeData(
        fontFamily: Platform.isIOS ? 'PingFang SC' : null,
        // 全局指定默认字体
        brightness: Brightness.light,
        // primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.transparent, // 设置Scaffold默认背景为透明
        dividerTheme: _dividerThemeData,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
        popupMenuTheme: const PopupMenuThemeData(
          color: Colors.white, // 这里设置你想要的颜色
          elevation: 0,
        ),
        // inputDecorationTheme: InputDecorationTheme(
        //   labelStyle: TextStyle(color: weakTextColor),
        //   // 更改标签颜色为蓝色
        //   // floatingLabelStyle: TextStyle(color: mainColor),
        //   // 更改浮动标签颜色为黑色
        //   errorStyle: const TextStyle(color: Colors.red),
        //   // 更改错误文本颜色为绿色
        //   focusedBorder: UnderlineInputBorder(
        //     borderSide: BorderSide(color: mainColor),
        //   ),
        //   focusedErrorBorder: const UnderlineInputBorder(
        //     borderSide: BorderSide(color: Colors.red),
        //   ),
        // ),
        appBarTheme: const AppBarTheme(
          scrolledUnderElevation: 0.2,
          backgroundColor: Colors.white,
          // color: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Color(0xff333333),
            fontSize: FontSize.large,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: IconThemeData(
            color: Color(0xff666666),
            size: 24,
          ),
        ),
        // 文本选择主题 - 统一使用主题色
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: mainColor, // 光标颜色
          selectionColor: mainColor.withOpacity(0.2), // 选择背景色 - 主题色的淡色版本
          selectionHandleColor: mainColor, // 选择手柄颜色
        ),
        // textButtonTheme: TextButtonThemeData(
        //   style: TextButton.styleFrom(
        //     foregroundColor: Colors.red, backgroundColor: Colors.white,
        //   ),
        // )
      );

  // 1. 主色调
  @override
  Color get mainColor => const Color(0xff4A9DF5);

  // 2. 用车事件主题色
  // 装备主色调
  @override
  Color get equipColor => const Color(0xff3BB2D0);

  // 加油主色调
  @override
  Color get refuelColor => const Color(0xff3887BE);

  // 充电主色调
  @override
  Color get chargeColor => const Color(0xff56B881);

  // 维修主色调
  @override
  Color get repairColor => const Color(0xff50667F);

  // 保养主色调
  @override
  Color get maintainColor => const Color(0xffFBB03B);

  // 保险主色调
  @override
  Color get insuranceColor => const Color(0xff41AFA5);

  // 改装主色调
  @override
  Color get remodelColor => const Color(0xffF9886C);

  // 其他主色调
  @override
  Color get eventOtherColor => const Color(0xffE55E5E);

  // 收入主色调
  @override
  Color get incomeColor => const Color(0xffED6498);

  // 3. 能耗信息配色
  // 加油
  @override
  Color get refuelInfoColor => const Color(0xffFADB14);

  // 里程
  @override
  Color get mileageInfoColor => const Color(0xff479BF6);

  // 经济
  @override
  Color get economyInfoColor => const Color(0xff95DE64);

  // 4. 背景色
  // 页面背景色
  @override
  Color get pageBackgroundColor => const Color(0xffF6F6F6);

  // 备注背景色
  @override
  Color get noteBackgroundColor => const Color(0xffF7F7FA);

  // 卡片背景色
  @override
  Color get cardBackgroundColor => const Color(0xffFFFFFF);

  // 控件背景色
  @override
  Color get widgetBackgroundColor => const Color(0xffEFF5FF);

  // 文字背景色
  @override
  Color get textBackgroundColor => const Color(0xffF1F9FF);

  // 5. 分割线
  @override
  Color get dividerColor => const Color(0xffE5E5E5);

  // 6. 文字色
  // 主色
  @override
  Color get mainTextColor => const Color(0xff4A9DF5);

  // 配色1-4
  @override
  Color get color1 => const Color(0xff08A459);

  @override
  Color get color2 => const Color(0xffC2650F);

  @override
  Color get color3 => const Color(0xffFF6533);

  @override
  Color get color4 => const Color(0xffFF6533);

  // 主标题
  @override
  Color get mainTitleColor => const Color(0xff313649);

  // 副标题和正文
  @override
  Color get subTitleColor => const Color(0xff666666);

  // 弱文案
  @override
  Color get weakTextColor => const Color(0xff999999);

  @override
  Color get placeholderColor => const Color(0xffC6C6C6);

  // 强调数字
  @override
  Color get strongNumTextColor => const Color(0xff565656);

  // 7. 蒙层
  @override
  Color get overlayColor => const Color.fromRGBO(255, 255, 255, 0.3);

  @override
  Color get rightArrowColor => Colors.grey.shade500;

  // 9 加油刻度安全颜色：比较充足
  @override
  Color get refuelSafeColor => const Color(0xff3DD59B);

  // 10 充电刻度安全颜色：比较充足
  @override
  Color get chargeSafeColor => const Color(0xff24C789);

  // 11 能源刻度背景色
  @override
  Color get energyBgColor => const Color(0xffECECEC);
}

class DarkOVSThemeData extends OVSThemeData {
  @override
  ThemeData get materialThemeData => ThemeData(
        brightness: Brightness.dark,
        // toggleableActiveColor: Colors.white,
        scaffoldBackgroundColor: Colors.transparent, // 设置Scaffold默认背景为透明
        primarySwatch: Colors.white.toMaterialColor(),
        dividerTheme: _dividerThemeData,
        popupMenuTheme: const PopupMenuThemeData(
          color: Colors.white, // 这里设置你想要的颜色
          elevation: 0,
        ),
        appBarTheme: const AppBarTheme(
            // color: Colors.white,
            elevation: 0,
            centerTitle: true,
            titleTextStyle: TextStyle(
              // color: Colors.black,
              fontSize: FontSize.large,
              fontWeight: FontWeight.w500,
            ),
            iconTheme: IconThemeData(
              color: Colors.white,
              size: 24,
            )),
        // 文本选择主题 - 统一使用主题色
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: mainColor, // 光标颜色
          selectionColor: mainColor.withOpacity(0.2), // 选择背景色 - 主题色的淡色版本
          selectionHandleColor: mainColor, // 选择手柄颜色
        ),
      );

  // 1. 主色调
  @override
  Color get mainColor => const Color(0xff4A9DF5);

  // 2. 用车事件主题色
  // 装备主色调
  @override
  Color get equipColor => const Color(0xff3BB2D0);

  // 加油主色调
  @override
  Color get refuelColor => const Color(0xff3887BE);

  // 充电主色调
  @override
  Color get chargeColor => const Color(0xff56B881);

  // 维修主色调
  @override
  Color get repairColor => const Color(0xff50667F);

  // 保养主色调
  @override
  Color get maintainColor => const Color(0xffFBB03B);

  // 保险主色调
  @override
  Color get insuranceColor => const Color(0xff41AFA5);

  // 改装主色调
  @override
  Color get remodelColor => const Color(0xffF9886C);

  // 其他主色调
  @override
  Color get eventOtherColor => const Color(0xffE55E5E);

  // 收入主色调
  @override
  Color get incomeColor => const Color(0xffED6498);

  // 3. 能耗信息配色
  // 加油
  @override
  Color get refuelInfoColor => const Color(0xffFADB14);

  // 里程
  @override
  Color get mileageInfoColor => const Color(0xff479BF6);

  // 经济
  @override
  Color get economyInfoColor => const Color(0xff95DE64);

  // 4. 背景色
  // 页面背景色
  @override
  Color get pageBackgroundColor => const Color(0xffF6F6F6);

  // 备注背景色
  @override
  Color get noteBackgroundColor => const Color(0xffF7F7FA);

  // 卡片背景色
  @override
  Color get cardBackgroundColor => const Color(0xffFFFFFF);

  // 控件背景色
  @override
  Color get widgetBackgroundColor => const Color(0xffEFF5FF);

  // 文字背景色
  @override
  Color get textBackgroundColor => const Color(0xffF1F9FF);

  // 5. 分割线
  @override
  Color get dividerColor => const Color(0xffE5E5E5);

  // 6. 文字色
  // 主色
  @override
  Color get mainTextColor => const Color(0xff4A9DF5);

  // 配色1-4
  @override
  Color get color1 => const Color(0xff08A459);

  @override
  Color get color2 => const Color(0xffC2650F);

  @override
  Color get color3 => const Color(0xffFF6533);

  @override
  Color get color4 => const Color(0xffFF6533);

  // 主标题
  @override
  Color get mainTitleColor => const Color(0xff313649);

  // 副标题和正文
  @override
  Color get subTitleColor => const Color(0xff666666);

  // 弱文案
  @override
  Color get weakTextColor => const Color(0xff999999);

  @override
  Color get placeholderColor => const Color(0xffCCCCCC);

  // 强调数字
  @override
  Color get strongNumTextColor => const Color(0xff565656);

  // 7. 蒙层
  @override
  Color get overlayColor => const Color.fromRGBO(255, 255, 255, 0.3);

  @override
  Color get rightArrowColor => Colors.grey.shade500;

  // 9 加油刻度安全颜色：比较充足
  @override
  Color get refuelSafeColor => const Color(0xff3DD59B);

  // 10 充电刻度安全颜色：比较充足
  @override
  Color get chargeSafeColor => const Color(0xff24C789);

  // 11 能源刻度背景色
  @override
  Color get energyBgColor => const Color(0xffECECEC);
}

extension on Color {
  Map<int, Color> _toSwatch() => {
        50: withOpacity(0.1),
        100: withOpacity(0.2),
        200: withOpacity(0.3),
        300: withOpacity(0.4),
        400: withOpacity(0.5),
        500: withOpacity(0.6),
        600: withOpacity(0.7),
        700: withOpacity(0.8),
        800: withOpacity(0.9),
        900: this,
      };

  MaterialColor toMaterialColor() => MaterialColor(
        value,
        _toSwatch(),
      );
}
