# Change 1: 安全与测试基础设施设计文档

> 日期：2026-05-04
> 来源：scaffold-maturity-upgrade 分解

---

## Context

脚手架当前缺失安全与测试基础设施：
- 路由无认证拦截，未登录用户可访问保护路径
- Domain 测试覆盖率低（仅 1 个 test），快速迭代回归风险高
- CI 无覆盖率可视化，测试进度不可观测

**约束**：
- 遵循 Clean Architecture + Feature-First 模式
- 新模块物理包隔离
- DI 遵循 Singleton/Factory 规范

---

## Goals / Non-Goals

**Goals**：
- 路由守卫环境控制启用（debug/staging 默认启用，prod 可配置）
- Domain 测试按风险优先覆盖（Phase 1 usecases 100%）
- CI 覆盖率双轨报告（codecov + 本地 HTML）
- Login/Register 示例页面（脚手架定位）
- 文档完整更新

**Non-Goals**：
- Sentry 接入（待收费评估）
- Widget/Golden 测试扩充（ROI 考量）
- 真实 API 对接（脚手架定位）
- Domain enums 测试（ROI 低，延后）

---

## Decisions

### D1: 路由守卫启用方式

**决策**：环境控制

| 环境 | 启用状态 |
|------|----------|
| debug | 默认启用 |
| staging | 默认启用 |
| prod | 可配置禁用 |

**理由**：
- 灵活性优先，不同环境不同策略
- 与 FPS 监控模式一致（环境控制）
- 避免 prod 强制启用影响特殊场景

**实现**：
```dart
enableAuthGuard: !EnvironmentConfig.isProd || EnvironmentConfig.enableAuthGuardOverride
```

---

### D2: 路由保护模式

**决策**：白名单模式

**白名单路径**：
- `/` — 首页
- `/login` — 登录页
- `/register` — 注册页

**理由**：
- 集中管理，默认安全
- 避免 `requiresAuth` 标记分散多处
- 修改白名单只需更新一处配置

**实现**：
```dart
// public_routes.dart
const publicRoutes = {'/', '/login', '/register'};
```

---

### D3: Domain 测试优先级

**决策**：按风险优先，分阶段覆盖

| Phase | 覆盖范围 | 目标 |
|-------|----------|------|
| Phase 1 | usecases | 100% |
| Phase 2 | models + exceptions | 按实际 |
| Phase 3 | enums | ROI低，延后 |

**理由**：
- usecases 包含业务逻辑，风险最高
- 分阶段降低一次性工作量
- 长期迭代逐步提升覆盖率

---

### D4: CI 覆盖率报告方式

**决策**：双轨

| 方式 | 用途 |
|------|------|
| codecov.io | CI 自动，PR 可见，团队共享 |
| 本地 HTML | 无网络依赖，快速查看 |

**理由**：
- codecov 网络问题时不丢失报告（artifact 兜底）
- 本地开发无需等待 CI
- 双轨兼顾，降低外部依赖风险

---

### D5: Login/Register 定位

**决策**：脚手架示例页面，无真实 API

**功能**：
- 简化 UI（用户名/密码输入）
- Mock 实现（`MockAuthRepository`）
- redirect 参数处理

**理由**：
- 脚手架定位为模板，不对接真实后端
- 示例页面供开发者参考结构
- 可快速替换为真实 API 实现

---

## Architecture

### 路由守卫模块

```
packages/infrastructure/routing/
├── lib/src/guards/
│   ├── auth_guard.dart          # check(state, auth) → redirect 或 null
│   └── public_routes.dart       # 白名单集合
└── lib/src/router/
    └── app_router.dart          # enableAuthGuard 参数
```

**数据流**：

```
用户导航 → GoRouter.redirect → AuthGuard.check → AuthManager.isLoggedIn → 决策
                                                              ↓
                                         未登录 + 非白名单 → '/login?redirect=...'
                                         已登录 或 白名单 → null
```

---

### Domain 测试结构

```
test/unit/domain/
├── usecases/
│   └── get_user_usecase_test.dart      # Phase 1
├── models/
│   └── user_test.dart                   # Phase 2
├── exceptions/
│   ├── domain_exception_test.dart       # Phase 2
│   └── network_exception_test.dart      # Phase 2
└── enums/                               # Phase 3（延后）
```

---

### CI 覆盖率配置

```
.github/workflows/
└── coverage.yml                         # codecov + artifact

scripts/
└── coverage_local.sh                    # 本地 HTML 生成

docs/
└── coverage-guide.md                    # 使用指南
```

---

### Login/Register Feature

```
packages/features/feature_auth/
├── lib/
│   ├── feature_auth.dart
│   ├── di/setup.dart
│   ├── cubit/auth_cubit.dart
│   ├── ui/login_page.dart
│   ├── ui/register_page.dart
│   └── repository/mock_auth_repository.dart
└── test/auth_cubit_test.dart
```

---

## Data Flow

### 路由守卫流程

```
1. 用户导航到 /profile
2. GoRouter.redirect 触发
3. AuthGuard.check 调用
4. AuthManager.isLoggedIn 查询
5. 未登录 + /profile 非白名单 → 返回 '/login?redirect=/profile'
6. GoRouter 跳转 login
7. 用户登录成功
8. AuthCubit 读取 redirect 参数
9. 跳转回 /profile
```

---

### Domain 测试流程

```
1. mocktail 创建 MockRepository
2. when() 设置 mock 返回值
3. usecase.execute() 执行
4. expect() 验证结果或异常
5. 测试通过 → 覆盖率记录
6. lcov 生成报告
7. codecov 上传 / HTML 本地查看
```

---

## Error Handling

### 路由守卫

| 错误场景 | 处理 |
|----------|------|
| AuthManager 未注册 | DI 启动时抛异常，阻止启动 |
| redirect 路径无效 | 兜底跳转 `/` |
| 白名单配置错误 | 单测覆盖，CI 阻断 |

---

### Domain 测试

| 错误场景 | 处理 |
|----------|------|
| mock 配置错误 | 测试失败，CI 阻断 |
| 覆盖率不达标 | CI warning，不阻断 |
| 测试超时 | 默认 30s 超时，需优化 |

---

### CI 覆盖率

| 错误场景 | 处理 |
|----------|------|
| codecov 上传失败 | `fail_ci_if_error: false`，artifact 兜底 |
| lcov 未安装 | 本地脚本提示安装命令 |
| 测试无覆盖率文件 | CI warning，artifact 为空 |

---

## Testing Strategy

### 路由守卫测试

```dart
// auth_guard_test.dart
class MockAuthManager extends Mock implements AuthManager {}

void main() {
  group('AuthGuard', () {
    test('白名单路径无 redirect', () {
      expect(AuthGuard.check('/', mockAuth), null);
    });

    test('未登录非白名单 redirect', () {
      when(() => mockAuth.isLoggedIn).thenReturn(false);
      expect(AuthGuard.check('/profile', mockAuth), '/login?redirect=/profile');
    });

    test('已登录无 redirect', () {
      when(() => mockAuth.isLoggedIn).thenReturn(true);
      expect(AuthGuard.check('/profile', mockAuth), null);
    });
  });
}
```

---

### Domain 测试示例

```dart
// get_user_usecase_test.dart
class MockUserRepository extends Mock implements UserRepository {}

void main() {
  late GetUserUseCase usecase;
  late MockUserRepository mockRepo;

  setUp(() {
    mockRepo = MockUserRepository();
    usecase = GetUserUseCase(mockRepo);
  });

  group('execute', () {
    test('成功返回 User', () async {
      when(() => mockRepo.getUser()).thenAnswer((_) async => User(id: '1'));
      final result = await usecase.execute();
      expect(result.id, '1');
    });

    test('失败抛异常', () async {
      when(() => mockRepo.getUser()).thenThrow(NetworkException());
      expect(() => usecase.execute(), throwsA(isA<DomainException>()));
    });
  });
}
```

---

### AuthCubit 测试

```dart
// auth_cubit_test.dart
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  group('AuthCubit', () {
    test('login 成功状态变更', () async {
      when(() => mockRepo.login('user', 'pass')).thenAnswer((_) async => true);
      await cubit.login('user', 'pass');
      expect(cubit.state.status, AuthStatus.loggedIn);
    });

    test('login 失败状态变更', () async {
      when(() => mockRepo.login('user', 'pass')).thenThrow(AuthException());
      await cubit.login('user', 'pass');
      expect(cubit.state.status, AuthStatus.error);
    });
  });
}
```

---

## Documentation

### 新建文档

| 文件 | 内容 |
|------|------|
| `docs/auth-route-guard.md` | 守卫启用、白名单、redirect 处理 |
| `docs/domain-testing-guide.md` | 测试分层、运行命令、mock 框架 |
| `docs/coverage-guide.md` | CI/本地双轨、覆盖率目标、常见问题 |

---

### README.md 新增章节

```markdown
## 路由守卫

环境自动启用（debug/staging）。白名单：`/`, `/login`, `/register`。

详细指南：[docs/auth-route-guard.md](docs/auth-route-guard.md)

## Domain 测试

按风险优先覆盖。Phase 1：usecases 100%。

详细指南：[docs/domain-testing-guide.md](docs/domain-testing-guide.md)

## Login/Register 示例

脚手架示例页面，无真实 API。位于 `packages/features/feature_auth/`。

## 测试覆盖率

双轨报告：CI codecov + 本地 HTML。

详细指南：[docs/coverage-guide.md](docs/coverage-guide.md)
```

---

## Acceptance Criteria

| 验收项 | 验证方式 |
|--------|----------|
| 路由守卫环境控制生效 | debug 启动 → 未登录访问 `/profile` → 跳转 login |
| 白名单路径可访问 | 未登录访问 `/` → 正常显示 |
| redirect 参数保留 | `/profile` → `/login?redirect=/profile` → 登录后回 `/profile` |
| Domain 测试 Phase 1 通过 | `flutter test test/unit/domain/usecases/` → 全 pass |
| Domain 测试覆盖率 100% | `flutter test --coverage` → usecases 覆盖率 100% |
| CI codecov 上传成功 | PR → codecov 评论可见 |
| 本地 HTML 生成成功 | `make coverage-local` → browser 打开报告 |
| login/register 页面可访问 | `/login`、`/register` → 页面显示 |
| login redirect 正确 | `/login?redirect=/settings` → 登录 → `/settings` |
| 文档更新完整 | README + docs/ 三个指南存在且完整 |

---

## Risks / Mitigations

### R1: AuthManager 状态同步延迟

**风险**：AuthManager 状态变更后，守卫可能未及时响应

**缓解**：
- AuthManager 使用 Cubit，状态变更自动 rebuild
- redirect 每次导航都检查，不依赖缓存

---

### R2: codecov 网络不稳定

**风险**：codecov 上传失败导致无报告

**缓解**：
- `fail_ci_if_error: false`，CI 不阻断
- artifact 兜底，可下载 HTML 查看
- 本地 HTML 作为备选

---

### R3: Domain 测试 ROI 低

**风险**：投入时间多，覆盖率提升慢

**缓解**：
- Phase 1 聚焦 usecases，风险最高 ROI 最高
- 分阶段推进，不一次性贪多
- 长期迭代逐步提升

---

## Implementation Order

```
1. 路由守卫 → 建立安全基础
2. Login/Register 示例页 → 路由守卫有实际场景
3. Domain 测试 Phase 1 (usecases) → 测试有内容
4. CI 覆盖率配置 → 测试报告上传
5. Domain 测试 Phase 2 (models/exceptions) → 逐步提升
6. 文档更新 → 验收
```

---

## References

- 原设计：`openspec/changes/scaffold-maturity-upgrade/design.md`
- 项目 README：`README.md`
- 架构评分：9.0/10