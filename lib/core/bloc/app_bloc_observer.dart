import 'package:error/error.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// 全局 Bloc 观察者
///
/// 职责：打印状态变化日志，捕获异常并上报到 AppErrorHandler
/// 使用：main.dart 启动前注册
class AppBlocObserver extends BlocObserver {
  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
    debugPrint('[BlocObserver] onCreate: ${bloc.runtimeType}');
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    debugPrint('[BlocObserver] ${bloc.runtimeType}: ${transition.currentState} → ${transition.nextState}');
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    debugPrint('[BlocObserver] ${bloc.runtimeType} ERROR: $error');
    debugPrint(stackTrace.toString());
    AppErrorHandler.instance.reportError(
      error,
      stackTrace,
      isFatal: true,
      context: {
        'source': 'bloc',
        'bloc': bloc.runtimeType.toString(),
      },
    );
  }
}
