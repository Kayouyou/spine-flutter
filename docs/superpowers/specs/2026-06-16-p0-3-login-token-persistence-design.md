# P0-3 登录 Token 持久化修复设计

> 日期: 2026-06-16
> 问题: 登录成功后 token 未保存到 TokenStorage，AuthCubit 状态未变化，AuthGuard 立即踢回 /login
> 决策: 方案 A — LoginCubit 通过 AuthManager 协调登录成功后的状态更新

---

## 0. 问题背景

### 当前流程（有 bug）

```
LoginPage 点登录
    ↓
LoginCubit.login()
    ↓
AuthRepository.login() → Result<LoginResult, DomainException>
    ↓
result.when(
  success: (_) => emit(LoginStatus.success),  ← 🔴 LoginResult 被丢弃
  ...
)
    ↓
LoginPage.listener: if (status == success) context.go('/home')
    ↓
AuthGuard 检查 AuthCubit.isLoggedIn
    ↓
AuthCubit 状态未变 → isLoggedIn = false
    ↓
🔴 被踢回 /login
```

### 根本原因

三个模块职责边界不清：

| 模块 | 当前职责 | 缺失职责 |
|------|---------|---------|
| **LoginCubit** | 驱动 UI 状态 (loading/success/error) | 不保存 token |
| **AuthCubit** | 持有登录状态 (loggedIn/loggedOut) | 没人驱动它变化 |
| **AuthManager** | 管理 token 存储 + 触发 AuthCubit | 没人调用它 |

**关键观察**：
- `LoginCubit.login()` 成功路径丢弃 `LoginResult`（`success: (_)`）
- `MockAuthRepository.login()` 返回 `LoginResult(token: 'mock-token-xxx', userId: 'mock-user-1')`
- `AuthManager.saveToken(token, userId)` 存在，但没人调用
- `AuthCubit.setAuthState()` 是唯一写入入口，但没人触发

---

## 1. 解决方案

### 方案 A：LoginCubit 直接调 AuthManager

**核心思路**：让 `AuthManager` 成为登录流程的必经节点，统一处理"登录成功后"的逻辑。

### 设计原则

1. **单一职责**：`LoginCubit` 只管 UI 状态，`AuthManager` 管业务逻辑
2. **显式依赖**：`LoginCubit` 直接依赖 `AuthManager`（feature → service 允许，R4）
3. **向后兼容**：`AuthRepository` 接口不变，`AuthManager` 新增方法
4. **测试友好**：`AuthManager` 可独立测试，`LoginCubit` mock `AuthManager`

---

## 2. 改动清单

### 2.1 新增方法：AuthManager.handleLoginSuccess

**文件**: `packages/services/auth/lib/src/manager.dart`

```dart
/// 处理登录成功后的状态更新
///
/// 职责：
/// 1. 保存 token 到 TokenStorage
/// 2. 保存 userId 到 TokenStorage
/// 3. 触发 AuthCubit 状态变化（AuthStatus.loggedIn）
///
/// 由 LoginCubit 在 login/register 成功后调用。
Future<void> handleLoginSuccess(LoginResult loginResult) async {
  await saveToken(loginResult.token, loginResult.userId);
  _authCubit.setAuthState(
    AuthState(status: AuthStatus.loggedIn, userId: loginResult.userId),
  );
  if (kDebugMode) {
    debugPrint('✅ [AuthManager] handleLoginSuccess: userId=${loginResult.userId}');
  }
}
```

### 2.2 LoginCubit 依赖 AuthManager

**文件**: `packages/features/feature_auth/lib/src/cubit/login_cubit.dart`

```dart
class LoginCubit extends Cubit<LoginState> {
  final AuthRepository _repository;
  final AuthManager _authManager;  // ← 新增依赖

  LoginCubit({
    required AuthRepository repository,
    required AuthManager authManager,  // ← 新增
  })  : _repository = repository,
        _authManager = authManager,
        super(const LoginState());

  Future<void> login() async {
    emit(state.copyWith(status: LoginStatus.loading));
    final result = await _repository.login(state.username, state.password);
    await result.when(
      success: (loginResult) async {
        await _authManager.handleLoginSuccess(loginResult);  // ← 核心改动
        emit(state.copyWith(status: LoginStatus.success, errorMessage: null));
      },
      failure: (error) => emit(state.copyWith(
        status: LoginStatus.error,
        errorMessage: error.message,
      )),
    );
  }

  Future<void> register() async {
    emit(state.copyWith(status: LoginStatus.loading));
    final result = await _repository.register(state.username, state.password);
    await result.when(
      success: (loginResult) async {
        await _authManager.handleLoginSuccess(loginResult);  // ← 核心改动
        emit(state.copyWith(status: LoginStatus.success, errorMessage: null));
      },
      failure: (error) => emit(state.copyWith(
        status: LoginStatus.error,
        errorMessage: error.message,
      )),
    );
  }
}
```

### 2.3 DI 注册更新

**文件**: `packages/features/feature_auth/lib/src/di/setup.dart`

```dart
void setupFeatureAuth(GetIt sl) {
  sl.registerFactory<LoginCubit>(() => LoginCubit(
    repository: sl<AuthRepository>(),
    authManager: sl<AuthManager>(),  // ← 新增
  ));

  RouteModuleRegistry.instance.register(
    'feature_auth',
    (ctx) => AuthRouteModule(
      ctx,
      createCubit: () => sl<LoginCubit>(),
    ),
  );
}
```

### 2.4 清理死代码：AuthCubit.login/logout

**文件**: `packages/services/auth/lib/src/cubit/auth_cubit.dart`

删除 `login()` 和 `logout()` 方法（无 production caller，P1-5）：

```dart
class AuthCubit extends Cubit<AuthState> {
  // final AuthRepository _repository;  ← 删除，不再需要
  // AuthCubit(this._repository) : super(const AuthState());  ← 删除

  AuthCubit() : super(const AuthState());  // ← 简化构造函数

  bool get isLoggedIn => state.status == AuthStatus.loggedIn;

  /// 外部唯一写入入口：仅 AuthManager 可调
  void setAuthState(AuthState newState) => emit(newState);

  // 删除 login() 和 logout() — 无 production caller
}
```

**同步更新**：
- `packages/services/auth/lib/src/di/setup.dart`：`AuthCubit` 注册不再传 `AuthRepository`
- `packages/services/auth/test/auth_cubit_test.dart`：删除 7 个 login/logout 相关 blocTest
- `packages/services/auth/test/auth_repository_factory_test.dart`：更新 mock

---

## 3. 修复后流程

```
LoginPage 点登录
    ↓
LoginCubit.login()
    ↓
AuthRepository.login() → LoginResult(token, userId)
    ↓
AuthManager.handleLoginSuccess(loginResult)
    ├─ TokenStorage.setToken(token)
    ├─ TokenStorage.setUserId(userId)
    └─ AuthCubit.setAuthState(loggedIn)  ← GoRouterRefreshStream 监听
    ↓
emit(LoginStatus.success)
    ↓
LoginPage.listener: context.go('/home')
    ↓
AuthGuard 检查: AuthCubit.isLoggedIn = true ✅
    ↓
🎉 进入 home 页面
```

---

## 4. 依赖方向合规性

```
feature_auth → domain (AuthRepository)      ✅ R1
feature_auth → auth service (AuthManager)   ✅ R4 允许 feature → service
auth service → domain (AuthRepository)      ✅ 
auth service ← feature_auth                 ✅ R4
```

**无违规**。

---

## 5. 测试策略

### 5.1 单元测试

| 测试文件 | 内容 |
|---------|------|
| `packages/services/auth/test/manager_test.dart` 新增 | `handleLoginSuccess` 调用 `saveToken` + `setAuthState` |
| `packages/features/feature_auth/test/login_cubit_test.dart` 更新 | mock `AuthManager`，验证 `handleLoginSuccess` 被调 1 次 |
| `packages/services/auth/test/auth_cubit_test.dart` 更新 | 删除 login/logout 相关 blocTest |

### 5.2 集成测试（可选，后续补充）

- 端到端：登录 → token 持久化 → 重启 app → 自动登录
- 场景：token 过期 → 401 → 续期 → 重试成功

---

## 6. 风险评估

| 风险 | 概率 | 影响 | 缓解措施 |
|------|:---:|:---:|---------|
| LoginCubit 构造函数变更导致现有测试失败 | 高 | 低 | 更新测试 mock |
| AuthCubit 删除 login/logout 导致其他测试失败 | 中 | 低 | 更新测试 |
| 注册流程也需要改（共用 LoginCubit） | 高 | 低 | register() 同样调 handleLoginSuccess |
| AuthManager 未注册到 GetIt | 低 | 高 | 检查 DI 配置，确保已注册 |

---

## 7. 工作量估算

| 任务 | 工作量 |
|------|:---:|
| AuthManager 新增 handleLoginSuccess | 15 分钟 |
| LoginCubit 改构造函数 + login/register | 30 分钟 |
| setup.dart DI 注册更新 | 10 分钟 |
| 删除 AuthCubit.login/logout | 15 分钟 |
| 更新单元测试 | 1 小时 |
| **总计** | **约 2 小时** |

---

## 8. 验收标准

- [ ] 登录成功后 token 保存到 TokenStorage
- [ ] AuthCubit 状态变为 loggedIn
- [ ] AuthGuard 通过，进入 home 页面
- [ ] 注册流程同样工作
- [ ] 重启 app 后自动登录（AuthManager.handleLogin 已存在）
- [ ] 所有单元测试通过
- [ ] `melos analyze` 无 warning/error
- [ ] `melos test:affected` 通过

---

## 9. 后续优化（不在本次范围）

- P1-5 清理 AuthCubit.login/logout 死代码（本次一起做）
- P2-1 UseCase 层透传问题（独立议题）
- 集成测试：端到端登录流程（后续补充）

---

## 附录：相关文件清单

```
packages/services/auth/lib/src/manager.dart              # 新增 handleLoginSuccess
packages/services/auth/lib/src/cubit/auth_cubit.dart     # 删除 login/logout
packages/services/auth/lib/src/di/setup.dart             # 更新 AuthCubit 注册
packages/features/feature_auth/lib/src/cubit/login_cubit.dart   # 改构造函数
packages/features/feature_auth/lib/src/di/setup.dart            # 更新 LoginCubit 注册

packages/services/auth/test/manager_test.dart                    # 新增测试
packages/services/auth/test/auth_cubit_test.dart                 # 删除测试
packages/features/feature_auth/test/cubit/login_cubit_test.dart  # 更新测试
```

---

*本文档基于方案 A 设计，已通过用户确认。下一步进入 writing-plans 阶段，生成实施计划。*
