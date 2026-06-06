# API Brick

一键创建 API 调用模块：Retrofit 接口 + Repository 实现 + DI 注册。

## Usage

```bash
mason make api \
  --name orders \
  --baseUrl /Order \
  --hasModel true \
  --modelName Order \
  --domainInterface IOrderRepository
```

## Variables

| 名称 | 类型 | 必填 | 默认 | 说明 |
|------|------|------|------|------|
| `name` | string | ✅ | — | API 模块名称（蛇形命名） |
| `baseUrl` | string | ✅ | — | API 基础路径 |
| `hasModel` | boolean | ❌ | `false` | 是否绑定数据模型 |
| `modelName` | string | ❌ | `dynamic` | 数据模型名（PascalCase） |
| `domainInterface` | string | ✅ | — | domain 接口名（含 I 前缀） |

> ⚠️ **WARNING: Mason 覆盖式写入**
>
> 本砖块会**完全覆盖**已存在的同名模块。运行前请备份现有代码。

## 硬规则 (AGENTS.md)

### R3: Infrastructure 不依赖 Services

DI 注册键为 `{{domainInterface}}`（接口），下游通过 `sl<{{domainInterface}}>()` 获取实例。

### R8: 错误走 DomainException

使用 `toDomainException(e)` 映射 `DioException` → `DomainException`，未知异常走 `UnknownException`。
