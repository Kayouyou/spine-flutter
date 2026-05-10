/// API 基础设施包
///
/// 提供 Dio 工厂函数和标准拦截器，不含业务 API 方法。
/// 业务 API 调用由各 RepositoryImpl 直接使用 Dio 完成。
export 'src/dio_factory.dart';
export 'src/http/http_event_bus.dart';
export 'src/http/http_constant.dart';
export 'src/http/token_supplier.dart';
// Phase 2新增：错误处理
export 'src/error/dio_mapper.dart';
// Phase 3.1新增：请求取消管理
export 'src/cancel/cancel_manager.dart';
export 'src/cancel/auto_cancel_interceptor.dart';
export 'src/dio/renewal_token_intercaptor.dart';  // Phase x: Token 续期拦截器
// Phase 3d新增：日志接口
export 'src/http/app_logger.dart';
export 'src/endpoints/api_endpoints.dart';
export 'src/constants/api_constants.dart';

// Retrofit API 接口
export 'src/api/home_api.dart';
export 'src/api/detail_api.dart';
export 'src/api/auth_api.dart';
export 'src/api/session_api.dart';
export 'src/api/vehicle_api.dart';
export 'src/models/login_request.dart';
export 'src/models/login_response.dart';
export 'src/models/user_profile.dart';
export 'src/models/home_data.dart';
export 'src/models/detail_data.dart';
export 'src/models/sign_in_request.dart';
export 'src/models/session_result.dart';
export 'src/models/vehicle_data.dart';
export 'src/models/update_profile_request.dart';
export 'src/api/user_api.dart';
