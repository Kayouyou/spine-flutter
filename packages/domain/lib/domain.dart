/// domain 层 — 纯 Dart 业务领域
///
/// 本包不依赖 Flutter，不依赖 infrastructure，可独立编译和测试。
/// 提供：数据模型、仓储接口、用例、枚举、异常定义。
library;
export 'src/config/app_config.dart';
export 'src/result.dart';
export 'src/usecases/get_user_usecase.dart';
export 'src/enums/enum.dart';
export 'src/exceptions/domain_exception.dart';
export 'src/models/user.dart';
export 'src/models/home_data.dart';
export 'src/models/detail_data.dart';
export 'src/models/login_result.dart';
export 'src/usecases/login_usecase.dart';
export 'src/usecases/get_home_data_usecase.dart';
export 'src/usecases/get_detail_data_usecase.dart';
export 'src/repositories/user_repository.dart';
export 'src/repositories/home_repository.dart';
export 'src/repositories/detail_repository.dart';
export 'src/repositories/auth_repository.dart';
export 'src/demo/demo_user.dart';
export 'src/demo/demo_response.dart';
