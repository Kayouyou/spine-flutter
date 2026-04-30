import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// App Starter — initializes Flutter binding and runs the app
class AppStarter {
  AppStarter._();

  static void start(Widget app) {
    WidgetsFlutterBinding.ensureInitialized();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]).then((_) {
      runApp(app);
    });
  }
}
