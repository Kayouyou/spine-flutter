# Domain Testing Guide

## 分层测试策略

| Phase | 覆盖范围 | 目标 |
|-------|----------|------|
| Phase 1 | usecases | 100% |
| Phase 2 | models + exceptions | 按实际 |
| Phase 3 | enums | ROI低，延后 |

## 测试位置

```
test/unit/domain/
├── usecases/     # Phase 1
├── models/       # Phase 2
├── exceptions/   # Phase 2
└── enums/        # Phase 3（延后）
```

## Mock 框架

使用 mocktail：

```dart
class MockUserRepository extends Mock implements UserRepository {}

when(() => mockRepo.getCurrentUser()).thenAnswer((_) async => User(id: '1'));
```

## 运行命令

```bash
# 运行 domain 测试
fvm flutter test test/unit/domain/

# 带覆盖率
fvm flutter test --coverage
```

## 命名规范

`<class>_test.dart`，如 `get_user_usecase_test.dart`。
