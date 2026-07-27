/// API 基础设施包
///
/// 提供 Dio 工厂函数和标准拦截器，不含业务 API 方法。
/// 业务 API 调用推荐使用 Retrofit 生成的 Api 类（如 HomeApi、DetailApi），
library;
export 'src/dio_factory.dart';
export 'src/http/http_event_bus.dart';
export 'src/http/http_constant.dart';
export 'src/http/api_config.dart';
export 'src/http/token_supplier.dart';
// Phase 2新增：错误处理
export 'src/error/dio_mapper.dart';
// Phase 3.1新增：请求取消管理
export 'src/cancel/cancel_manager.dart';
export 'src/cancel/auto_cancel_interceptor.dart';
export 'src/dio/renewal_token_interceptor.dart';  // Phase x: Token 续期拦截器
export 'src/dio/error_interceptor.dart';  // Phase x: Dio 错误拦截器(上报到 AppErrorHandler)
export 'src/dio/response_envelope_interceptor.dart';  // Task7: 统一业务信封解包 + 业务码→BusinessException
export 'src/dio/cache_interceptor.dart';  // Task8: 通用 GET 响应缓存拦截器 + CacheStrategy
export 'src/dio/circuit_breaker.dart';  // Phase: 熔断器 CircuitBreaker
export 'src/dio/retry_interceptor.dart';  // Phase: 重试拦截器 RetryInterceptor
// Phase 3d新增：日志接口
export 'src/http/app_logger.dart';
export 'src/endpoints/api_endpoints.dart';
// 刷新: 新增 refresh_queue + refresh_api
export 'src/refresh/refresh_api.dart';
export 'src/refresh/refresh_queue.dart';

// 离线请求队列 RequestQueue
export 'src/dio/request_queue.dart';
export 'src/dio/network_status_interceptor.dart';  // Task5: 断网入队/恢复重发拦截器

// 网络环境抽象（R3：infra 内自包含，供 services 桥接实现）
export 'src/network/network_environment.dart';

// Retrofit API 接口
export 'src/api/home_api.dart';
export 'src/api/detail_api.dart';
export 'src/models/user_profile.dart';
export 'src/models/home_data.dart';
export 'src/models/detail_data.dart';
export 'src/models/update_profile_request.dart';
export 'src/api/user_api.dart';
