# domain

纯 Dart 业务领域层 — 不依赖 Flutter SDK。

## 职责

| 目录 | 内容 | 依赖 Flutter |
|------|------|-------------|
| models/ | 共用数据模型 | 否（纯 Dart） |
| repositories/ | 仓储抽象接口 | 否 |
| usecases/ | 业务逻辑编排（UseCase） | 否 |
| exceptions/ | 领域异常体系（sealed class） | 否 |
| enums/ | 共用枚举 | 否 |
| config/ | 应用配置抽象（IAppConfig） | 否 |
| result.dart | 统一结果类型 Result\<T, E\> | 否 |

## 依赖方向

```
domain (纯 Dart, 只依赖 equatable)
  ↑
infrastructure (api, routing, key_value_storage)
  ↑
services, features
```

## UseCase 层

### UseCase 放在 domain 合理吗？

合理。UseCase 是纯业务逻辑编排，不依赖 Flutter、不依赖具体实现，只依赖 domain 层定义的仓储接口。这完全符合 Clean Architecture 中"domain 层包含用例"的标准做法。

### 什么时候需要 UseCase 层？

**判断标准：Cubit 调 Repository 是"一句话"还是"好几步"。**

- **不需要 UseCase** — Cubit 就调一个 repository 方法，一行代码搞定
- **需要 UseCase** — Cubit 要调好几个 Repository、做判断、编排流程、处理异常回滚

**不需要 UseCase 的例子（当前项目）：**

```dart
// LoginCubit - 登录就调一个 repository.login()，不需要中间商
class LoginCubit extends Cubit<LoginState> {
  final AuthRepository _authRepo;
  
  Future<void> login(String email, String password) async {
    final result = await _authRepo.login(email, password);
    result.when(
      success: (_) => emit(LoginState.success()),
      failure: (e) => emit(LoginState.error(e.message)),
    );
  }
}
```

**需要 UseCase 的例子：**

```dart
// 如果登录需要做很多事：验证 → 调 API → 存 Token → 触发数据同步 → 发送通知
class LoginUseCase {
  final AuthRepository _authRepo;
  final TokenStorage _tokenStorage;
  final DataSyncManager _syncManager;

  Future<Result<void, DomainException>> execute(String email, String password) async {
    // 1. 调登录 API
    final loginResult = await _authRepo.login(email, password);
    if (loginResult.isFailure) return loginResult;

    // 2. 保存 Token
    await _tokenStorage.saveToken(loginResult.token);

    // 3. 触发数据同步
    await _syncManager.sync();

    return Result.success(null);
  }
}
```

**一句话：Cubit 是 UI 状态管理者，UseCase 是业务逻辑编排者。**

## 关键设计

- **不依赖 Flutter** — 可独立编译和测试
- **Repository 接口** — domain 定义接口，services/features 实现
- **Sealed 异常** — `DomainException` 是 sealed class，保证穷尽性匹配

## Result<T, E> 模式

域层提供统一的 `Result<T, E>` 类型用于显式错误处理。

### 使用方式

```dart
// 仓储返回 Result
Future<Result<User, DomainException>> getCurrentUser();

// 调用方通过 when 穷尽匹配
final result = await repository.getCurrentUser();
result.when(
  success: (user) => print(user.name),
  failure: (error) => showError(error),
);
```

### 核心类型
- `Result<T, E>` — 密封基类
- `Success<T, E>` — 成功结果，包含数据 `data`
- `Failure<T, E>` — 失败结果，包含异常 `error`
- `Future.toResult()` — 自动将 Future 转换为 Result（api 包提供）
