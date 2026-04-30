# API 开发指南

> 本文档说明如何在项目中新增 API 接口。2025/04 重构后，所有 Request 文件已删除，改用 fluent builder 模式。

## 快速参考

### 方式一：使用 Skill 自动生成（推荐）

```bash
# 在项目根目录下，与 Claude 对话时输入：
/ovsx-add-api

# 或提供 JSON 格式的 API 规范：
{
  "api_path": "/Vehicle/Ranking/Query/Top/Info",
  "http_method": "POST",
  "need_login": true,
  "response_example": {
    "UserId": "xxx",
    "VehicleId": "xxx",
    "BrandName": "奔驰"
  }
}
```

Skill 会自动生成：
- API Mixin 方法
- Remote Model (RM)
- Domain Model (DM)
- Mapper Extensions
- Repository Extension
- 更新所有导出文件

### 方式二：手动添加

按照以下步骤手动添加：

## Step 1：API Mixin 方法

**文件位置**：追加到已有文件，或新建文件
- `packages/api/lib/src/modules/<domain>/<domain>_api.dart`

**模板**：

```dart
mixin XxxApiMixin on ApiBase {
  Future<XxxRM> queryXxx({
    required String param1,
    String? param2,
  }) async {
    final response = await httpManager
      .post('/Xxx/Yyy')
      .addParam('Param1', param1)
      .addParam('Param2', param2)
      .fire();
    return XxxRM.fromJson(response);
  }
}
```

**fluent builder API**：

| 方法 | 说明 |
|------|------|
| `httpManager.post('/path')` | 创建 POST 请求 |
| `httpManager.get('/path')` | 创建 GET 请求 |
| `.addParam('key', value)` | 添加参数（自动过滤 null 和空字符串） |
| `.addParams({'key': value})` | 批量添加参数 |
| `.fire()` | 执行请求，返回 `dynamic` |

**注意**：路径**不含 `/api` 前缀**，直接以 `/Domain/Verb/...` 开头。

## Step 2：Remote Model (RM)

**文件位置**：`packages/api/lib/src/models/response/<domain>/<name>_rm.dart`

**模板**：

```dart
import 'package:json_annotation/json_annotation.dart';

part '<name>_rm.g.dart';

@JsonSerializable()
class XxxRM {
  final String Id;
  final String? BrandName;

  XxxRM({
    required this.Id,
    this.BrandName,
  });

  factory XxxRM.fromJson(Map<String, dynamic> json) =>
      _$XxxRMFromJson(json);

  Map<String, dynamic> toJson() => _$XxxRMToJson(this);
}
```

**命名规则**：保持后端命名风格（`Id`, `UserId`, `BrandName`）。

## Step 3：Domain Model (DM)

**文件位置**：`packages/domain_models/lib/src/<domain>/<name>.dart`

**模板**：

```dart
import 'package:equatable/equatable.dart';

class Xxx extends Equatable {
  final String id;
  final String? brandName;

  const Xxx({
    required this.id,
    this.brandName,
  });

  @override
  List<Object?> get props => [id, brandName];
}
```

## Step 4：Mapper Extension

**文件位置**：`packages/<repo>/lib/src/mappers/remote_to_domain.dart`

**模板**：

```dart
extension XxxRMToDomain on XxxRM {
  Xxx toDomainModel() {
    return Xxx(
      id: Id,
      brandName: BrandName,
    );
  }
}
```

## Step 5：Repository Extension

**文件位置**：`packages/<repo>/lib/src/extensions/<domain>_extension.dart`

**模板**：

```dart
extension XxxQuery on XxxRepository {
  Future<Xxx> queryXxx({
    required String param1,
  }) async {
    final rm = await remoteApi.queryXxx(param1: param1);
    return rm.toDomainModel();
  }
}
```

**注意**：API 层的 `fire()` 已自动将 `HttpsException` 转为 `DomainException`，Repository 层无需 try-catch。

## Step 6：注册到导出文件

### 如果新建 mixin 文件

**modules.dart**（`packages/api/lib/src/modules/modules.dart`）：

```dart
export '<domain>/<name>_api.dart';
```

**api.dart**（`packages/api/lib/src/api.dart`）：

```dart
class Api extends ApiBase
    with
        // ... 已有 mixin ...
        XxxApiMixin,     // ← 追加此处
```

### 所有情况都需要

**models.dart**（`packages/api/lib/src/models/models.dart`）：

```dart
export 'response/<domain>/<name>_rm.dart';
```

**domain_models.dart**（`packages/domain_models/lib/domain_models.dart`）：

```dart
export 'src/<domain>/<name>.dart';
```

## Step 7：运行 build_runner

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## 功能域推断

从 API 径自动推断领域（路径不含 `/api` 缀）：

| API 径前缀 | 功能域 | 已有 mixin 文件 |
|-------------|--------|----------------|
| `/Vehicle/...` | car | `car/car_api.dart` |
| `/User/...` | user | `user/user_api.dart` |
| `/Device/Gps/...` | location | `location/device_location_api.dart` |
| `/Track/...` | track | `location/track_location_api.dart` |
| `/Story/...` | story | `location/story_api.dart` |
| `/Commerce/...` | commerce | `commerce/goods_api.dart` |
| `/Message/...` | messaging | `messaging/messages_api.dart` |
| `/OSS/...` | oss | `utils/oss_api.dart` |
| `/Tools/Weather/...` | weather | `utils/weather_api.dart` |

## 目录结构

```
packages/api/lib/
  api.dart                              # Api 主类（组合所有 mixin）
  src/
    api.dart                            # Api 类实现
    api_base.dart                       # Api 基类
    http/
      http_manager.dart                 # HTTP 管理器
      ...
    modules/
      modules.dart                      # 所有 mixin 的 export 汇总
      user/                             # 用户相关
      car/                              # 车辆相关
      location/                         # 位置/轨迹/围栏
      commerce/                         # 商务
      messaging/                        # 消息推送
      utils/                            # 工具类 API
      analytics/                        # 埋点
      operation/                        # 使用说明
    models/
      models.dart                       # 所有 RM 的 export 汇总
      response/
        <domain>/<name>_rm.dart         # Remote Model
```

## 相关 Skill

| Skill | 说明 |
|------|------|
| `/ovsx-add-api` | API 全链路生成器（推荐） |
| `/ovsx-add-hive-model` | Hive 缓存模型生成器 |
| `/ovsx-add-test` | 测试文件生成 |
| `/ovsx-review` | 合规审查 |

## 常见问题

### Q1: 路径格式是什么？
不含 `/api` 前缀，直接以 `/Domain/Verb/...` 开头。例如 `/User/Login/Password`。

### Q2: Repository 层需要 try-catch 吗？
不需要。`fire()` 已自动将异常转为 `DomainException`。

### Q3: 参数名大小写？
与后端一致。例如后端参数 `TargetVehicle`，则 `addParam('TargetVehicle', value)`。

### Q4: 返回列表怎么处理？
```dart
Future<List<XxxRM>> queryXxxList() async {
  final response = await httpManager.post('/Xxx/List').fire();
  if (response is List) {
    return response.map((e) => XxxRM.fromJson(e)).toList();
  }
  return [];
}
```