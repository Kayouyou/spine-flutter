# packages 目录

## 职责

`packages/` 存放**可复用的独立 Dart/Flutter 包**。每个包有独立 `pubspec.yaml`，可被主 app 或其他包引用。

## 包的分类

```
packages/
├── 基础设施层（已有）
│   ├── api/                    ← API 请求管理
│   ├── domain_models/          ← 领域模型和异常
│   ├── key_value_storage/      ← 键值存储（Hive）
│   ├── component_library/      ← 通用 UI 组件库
│   └── routing/                ← 路由配置
│
├── 共享业务层（提取中）
│   ├── auth/                   ← 认证管理
│   ├── data_sync/              ← 数据同步
│   ├── app_logger/             ← 日志系统
│   └── app_constants/          ← 配置常量
│
└── 业务功能层（features/ 子目录）
    ├── feature_home/           ← 首页模块
    ├── feature_detail/         ← 详情模块
    ├── feature_user/           ← 用户模块（预留）
    └── feature_order/          ← 订单模块（预留）
```

### 1. 基础设施包

**特征**：纯技术实现，和业务无关，可跨项目复用。

| 示例 | 说明 |
|------|------|
| `api/` | Dio 封装、请求管理、拦截器 |
| `domain_models/` | 数据模型、ErrorCode、异常定义 |
| `key_value_storage/` | Hive 封装的键值存储 |
| `component_library/` | 通用 Widget 组件 |
| `routing/` | GoRouter 路由配置 |

### 2. 共享业务包

**特征**：包含业务逻辑，但被多个 feature 共享，不是某个 feature 专属。

| 示例 | 说明 |
|------|------|
| `auth/` | 登录、Token 管理、权限检查 |
| `data_sync/` | 登录后的数据同步逻辑 |
| `app_logger/` | 分级日志系统 |
| `app_constants/` | App/API/Cache 配置常量 |

### 3. 业务功能包（features/）

**特征**：实现具体业务功能，每个包对应一个用户可见的功能模块。

| 示例 | 说明 |
|------|------|
| `features/feature_home/` | 首页：页面、Cubit、Repository |
| `features/feature_detail/` | 详情页：页面、Cubit、Repository |

每个 feature 包标准结构：
```
features/feature_home/
├── lib/
│   ├── feature_home.dart    ← barrel file（唯一公开出口）
│   └── src/
│       ├── repository/
│       ├── cubit/
│       └── ui/
├── test/
└── pubspec.yaml
```

## 判断标准

### 该放进 packages/ 的

- 有独立职责的模块
- 可能被多个地方引用
- 有自己专属的依赖声明（pubspec.yaml）
- 需要独立测试
- 将来可能跨项目复用

### 不该放进 packages/ 的

- 只是目录组织需要（用 `lib/` 子目录就行）
- 只在主 app 内部使用、不会被其他模块引用
- 主 app 的入口逻辑（main.dart 放 lib/ 根）
- 主 app 的组装逻辑（di/、startup/ 放 lib/core/）

## 依赖规则

```
依赖方向（只能向下）

主 app (lib/)
  └──▶ 基础设施包 (api, domain_models...)
        └──▶ 共享业务包 (auth, app_logger...)
              └──▶ 业务功能包 (features/feature_home...)

禁止：
  ✗ 业务包 import 主 app
  ✗ 基础设施包 import 业务包
  ✗ 同级业务包互相 import（除非 pubspec 显式声明）
```
