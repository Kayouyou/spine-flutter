import 'package:component_library/src/theme/ovs_theme_data.dart';
import 'package:flutter/material.dart';

class OVSTheme extends InheritedWidget {
  const OVSTheme({
    required Widget child,
    required this.lightTheme,
    required this.darkTheme,
    Key? key,
  }) : super(
          key: key,
          child: child,
        );

  final OVSThemeData lightTheme;
  final OVSThemeData darkTheme;

  @override
  bool updateShouldNotify(
    OVSTheme oldWidget,
  ) =>
      oldWidget.lightTheme != lightTheme || oldWidget.darkTheme != darkTheme;

  static OVSThemeData of(BuildContext context) {
    // Obtains the nearest widget in the widget tree of the WonderTheme type and
    // stores it in the variable.
    final OVSTheme? inheritedTheme =
        context.dependOnInheritedWidgetOfExactType<OVSTheme>();

    if (inheritedTheme == null) {
      final currentBrightness = Theme.of(context).brightness;
      return currentBrightness == Brightness.dark
          ? DarkOVSThemeData()
          : LightOVSThemeData();
    }

    assert(inheritedTheme != null, 'No OvsTheme found in context');
    final currentBrightness = Theme.of(context).brightness;
    return currentBrightness == Brightness.dark
        ? inheritedTheme!.darkTheme
        : inheritedTheme!.lightTheme;
  }
}
