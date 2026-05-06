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

class EventKeys {
  static const String logout = "Logout";
  static const String hasToken = "hasToken";
}
