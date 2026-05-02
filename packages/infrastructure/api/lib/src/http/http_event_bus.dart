class HttpEventBus {
  //私有构造函数
  HttpEventBus._internal();

  static HttpEventBus? _instance;

  static HttpEventBus get instance => _getInstance();

  static HttpEventBus _getInstance() {
    return _instance ??= HttpEventBus._internal();
  }

  bool isTest = false;

  // 存储事件回调方法
  final Map<String, Function> _events = {};

  // 设置事件监听
  void addListener(String eventKey, Function callback) {
    _events[eventKey] = callback;
  }

  // 移除监听
  void removeListener(String eventKey) {
    _events.remove(eventKey);
  }

  // 提交事件
  void commit(String eventKey) {
    _events[eventKey]?.call();
  }
}

enum OVSTap {
  home,
  car,
  find,
  story,
  mine,
}

class EventKeys {
  static const String logout = "Logout";
  static const String hasToken = "hasToken";
  static const String addNewCar = "addNewCar";
  static const String updateLogs = "updateLogs";
  static const String hideTabBar = "hideTabBar";
  static const String showTabBar = "showTabBar";
  static const String exchangeTab = "exchangeTab";
  static const String updateWeather = "updateWeather";
  static const String updateCar = "updateCar";
  static const OVSTap homeTap = OVSTap.home;
}
