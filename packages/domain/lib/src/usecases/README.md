# UseCase 层架构说明

## 设计原则

UseCase 层作为 **可选的业务逻辑编排层**，用于处理以下场景：

1. **组合多个 Repository**：当一个业务操作需要协调多个数据源时
2. **业务验证逻辑**：在调用 Repository 前添加输入验证、权限检查等
3. **跨 Repository 事务**：需要保证多个 Repository 操作的原子性时
4. **复杂业务流程**：涉及多个步骤、需要状态管理的业务场景

## 当前状态

当前实现采用 **透传模式**，UseCase 直接委托给 Repository：

```dart
class LoginUseCase {
  Future<Result<LoginResult, DomainException>> execute({...}) async {
    return _authRepository.login(username, password);  // 直接透传
  }
}
```

## 何时需要扩展 UseCase

当出现以下情况时，应在 UseCase 层添加逻辑：

### 1. 输入验证
```dart
class LoginUseCase {
  Future<Result<...>> execute({...}) async {
    if (username.isEmpty) return Result.failure(ValidationError('用户名不能为空'));
    if (password.length < 6) return Result.failure(ValidationError('密码至少6位'));
    return _authRepository.login(username, password);
  }
}
```

### 2. 组合多个 Repository
```dart
class RegisterUseCase {
  Future<Result<...>> execute({...}) async {
    // 1. 创建用户
    final userResult = await _userRepository.create(data);
    if (userResult.isFailure) return userResult;
    
    // 2. 发送验证邮件
    return _emailRepository.sendVerification(userResult.value.email);
  }
}
```

### 3. 业务规则编排
```dart
class TransferUseCase {
  Future<Result<...>> execute({...}) async {
    // 检查余额
    final balance = await _accountRepository.getBalance(fromAccount);
    if (balance < amount) return Result.failure(InsufficientFunds());
    
    // 执行转账
    return _accountRepository.transfer(fromAccount, toAccount, amount);
  }
}
```

## 何时可以直接调用 Repository

**简单场景**下可以跳过 UseCase 层，直接调用 Repository：

- 单一 Repository 的 CRUD 操作
- 不需要额外业务验证的查询
- 纯数据获取（如获取用户信息、获取列表数据）

示例：
```dart
// ❌ 不推荐的无意义包装
class GetUserUseCase {
  Future<Result<User, ...>> execute(String id) async {
    return _userRepository.getById(id);  // 纯透传，无额外逻辑
  }
}

// ✅ 推荐：直接调用 Repository
final user = await userRepository.getById(userId);
```

## 架构决策记录

**ADR-2026-06: UseCase 层保留策略**

- **状态**：已采纳
- **背景**：当前 UseCase 层全部是透传实现，存在"是否有必要保留"的疑问
- **决策**：保留 UseCase 层作为扩展点，允许简单场景直接调用 Repository
- **理由**：
  1. UseCase 层为未来业务复杂度增长预留空间
  2. 避免大规模重构（删除 UseCase 层需要修改所有调用方）
  3. 保持 Clean Architecture 的分层完整性
  4. 新开发者可以根据业务需要决定是否在 UseCase 层添加逻辑

## 迁移指南

### 场景 1: 添加业务验证
在 UseCase 的 `execute` 方法开头添加验证逻辑：

```dart
Future<Result<...>> execute({...}) async {
  // 新增：输入验证
  if (input.isInvalid) return Result.failure(ValidationError());
  
  // 原有：Repository 调用
  return _repository.doSomething(input);
}
```

### 场景 2: 直接调用 Repository
如果 UseCase 只是透传，且未来不太可能需要业务逻辑，可以：

1. 删除 UseCase 类
2. 修改调用方（通常是 Cubit/Bloc）直接使用 Repository
3. 更新依赖注入配置

## 测试策略

UseCase 测试应覆盖：

1. **输入验证逻辑**（如果有）
2. **Repository 调用的编排顺序**
3. **错误处理**（Repository 失败时的行为）
4. **边界条件**（空值、极端值等）

示例：
```dart
test('LoginUseCase should validate password length', () async {
  final result = await useCase.execute(username: 'user', password: '123');
  expect(result.isFailure, isTrue);
  expect(result.failure, isA<ValidationError>());
});
```
