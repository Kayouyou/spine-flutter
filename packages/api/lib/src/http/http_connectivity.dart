// import 'package:connectivity_plus/connectivity_plus.dart';
//
// /// Checking if the device is connected to the internet.
// class NetworkConnectivity {
//   /// Checking if the device is connected to the internet.
//   static Future<bool> get connected async {
//     var connectivityResult = await (Connectivity().checkConnectivity());
//     if (connectivityResult == ConnectivityResult.none) {
//       return false;
//     } else {
//       return true;
//     }
//   }
// }
// 添加网络状态监听
// import 'package:connectivity/connectivity.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkConnectivity {
  /// Checking if the device is connected to the internet.
  static Future<bool> get connected async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      return false;
    } else {
      return true;
    }
  }

  /// checking  wifi
  static Future<bool> get isWifi async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.wifi) {
      return true;
    } else {
      return false;
    }
  }
}
