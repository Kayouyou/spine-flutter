/// Routing package — GoRouter setup with RouteModule pattern
///
/// This package provides the core routing infrastructure:
/// - RouteModule: Base class for feature route modules
/// - RouteModuleRegistry: Registry for collecting feature route modules
/// - RouteContext: Dependency container for route modules
/// - AuthGuard: Route guard for authentication
/// - RouteObserver: Route change observer

export 'src/routes/routes.dart';
export 'src/routes/route_module.dart';
export 'src/routes/route_module_registry.dart';
export 'src/routes/route_context.dart';
export 'src/routes/app_routes.dart';
export 'src/guards/auth_guard.dart';
export 'src/guards/public_routes.dart';
export 'src/route_observer.dart';
export 'src/mixins/app_lifecycle_mixin.dart';
export 'src/mixins/lifecycle_mixin.dart';
export 'src/mixins/full_lifecycle_mixin.dart';
