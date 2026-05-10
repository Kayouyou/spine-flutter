# Findings

## 本轮初始观察
- 代码树显示 `packages/domain/lib/src/models/` 新增了 `home_data.dart` 和 `detail_data.dart`
- `bricks/feature` 模板新增了 `routes/{{name}}_route_module.dart`
- `packages/infrastructure/key_value_storage` 结构被明显收缩，旧的 token/migration/shared_preferences 相关文件不再出现在当前代码树主列表里
- `git diff --stat` 为空，说明当前工作区干净，适合按现状做一次完整审计

## 中期发现
- `domain` 仓储接口已从 `Map<String, dynamic>` 升级为 `HomeData` / `DetailData`
- `feature_auth` 已改为通过路由层注入 `LoginCubit`，页面层不再直接 new `MockAuthRepository`
- `feature_detail` 已改成 `LifecycleMixin.onPageEnter()` 触发加载，避免 `build()` 重复请求
- `RouteModuleRegistry` 已实现，但 `app.dart` 仍手动列举 `HomeRouteModule/AuthRouteModule/DetailRouteModule`，未真正使用 `buildAll(ctx)`
- `melos.yaml` 已把根应用 `.` 纳入 workspace，但 `make test` 仍调用 `melos test`，根测试也会一起跑出失败
- 当前主要失败来自旧测试未升级：`AuthGuard` 签名已改为 `bool Function()`；`AuthRepositoryImpl` 构造函数已从 `Dio` 改成 `UserApi`；根层 Home 测试仍用旧 `Map` 类型
- CI 仍只跑 `flutter analyze` 和 `melos test`，没有显式做资源目录存在性校验；当前 `pubspec.yaml` 声明了 `assets/images/` 与 `assets/fonts/`，但实际目录不存在
- `feature_detail` 包内测试失败原因是断言写成 `runtimeType == DetailError`，和 freezed 生成实现类不兼容，不是业务逻辑错误
