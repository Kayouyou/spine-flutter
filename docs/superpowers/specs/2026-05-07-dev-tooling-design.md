# Dev Tooling — Melos + Mason

**日期**: 2026-05-07  
**状态**: 设计确认  
**范围**: 引入 Melos（多包管理）和 Mason（代码模板生成）

---

## 背景

当前项目是 14 个本地包的 Flutter Monorepo，存在以下问题：

1. **CI 测试盲区**：`flutter test` 在根目录运行，仅覆盖根目录 14 个测试文件，`packages/` 下 27 个测试文件完全被跳过
2. **依赖管理手动**：Makefile 手动逐个 `cd packages/xxx && pub get`，新增包容易遗漏
3. **新建功能繁琐**：`make create-feature` 只是文字提示，实际需手动创建 8 个文件

---

## 方案

### 1. Melos 集成

#### 1.1 melos.yaml

```yaml
name: my_app
packages:
  - packages/domain
  - packages/infrastructure/*
  - packages/services/*
  - packages/features/*

scripts:
  analyze:
    run: melos exec -- flutter analyze
    description: 全量代码分析
  test:
    run: melos exec -- flutter test
    description: 所有包测试
  test:affected:
    run: melos exec --since=origin/main --diff=origin/main -- flutter test
    description: 只测变更相关包
```

#### 1.2 Makefile 改动

Makefile 与 Melos **共存**：

- `make get` → `melos bs`（自动扫描所有包）
- `make test` → `melos test`
- `make lint` → `melos analyze`
- 构建命令（debug, release, dev/staging/prod）保留不变

#### 1.3 CI 改动

**ci.yml test job**：
```yaml
- run: melos bs
- run: melos test --coverage
```

**coverage.yml**：
```yaml
- run: melos bs
- run: melos test --coverage
```

#### 1.4 Pre-commit Hook 改动

```bash
melos exec --since=origin/main --diff=origin/main -- flutter test
```

只跑变更相关包的测试，秒级完成。

---

### 2. Mason 集成

#### 2.1 安装

```bash
dart pub global activate mason_cli
mason init
```

#### 2.2 Feature Brick

一个 `feature` brick，模板化生成以下结构：

```
feature_{{name}}/
├── pubspec.yaml
├── lib/
│   ├── feature_{{name}}.dart          # 导出入口
│   ├── di/
│   │   └── setup.dart                  # DI 注册
│   ├── cubit/
│   │   ├── {{name}}_cubit.dart
│   │   └── {{name}}_state.dart
│   ├── repository/
│   │   └── {{name}}_repository.dart
│   └── ui/
│       └── {{name}}_page.dart
└── test/
    └── {{name}}_cubit_test.dart
```

使用方式：
```bash
mason make feature --name settings
```

#### 2.3 模板内容规范

- State 使用 `@freezed`（匹配现有规范）
- Cubit 包含 loading/loaded/error 三种标准状态
- Repository 实现 `interface` 在 domain 的模式
- DI setup 依赖 `get_it`

---

## 验收标准

### Melos
- [ ] `melos bs` 正确安装所有 14 个包的依赖
- [ ] `melos test` 跑全部 41 个测试文件且全部通过
- [ ] `melos analyze` 零 error
- [ ] CI 的 test job 覆盖所有包（非仅根目录）
- [ ] Pre-commit hook 仅跑变更包测试（`--since`）
- [ ] `make get` / `make test` / `make lint` 等旧命令仍可用

### Mason
- [ ] `mason make feature --name test` 生成 `feature_test/` 包，结构正确
- [ ] 生成的代码通过 `flutter analyze`
- [ ] 生成的代码包含正确的 test 文件模板
- [ ] `mason.yaml` 存在于项目根目录

---

## 不涉及

- 不改动现有业务逻辑
- 不修改 domain/models/use cases
- 不添加新的业务功能
