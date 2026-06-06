// Project imports:
import 'injectable.dart';

export 'injectable.dart' show getIt;

/// 简写：sl<AuthManager>() 等价于 getIt<AuthManager>()
///
/// 注意：sl 只是 getIt 的别名，不要直接 import GetIt.instance
final sl = getIt;