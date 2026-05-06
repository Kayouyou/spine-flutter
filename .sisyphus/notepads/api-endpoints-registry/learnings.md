## Task 1: API 端点注册表 — 完成

**文件创建:**
- `packages/infrastructure/api/lib/src/endpoints/api_endpoints.dart` — 68 lines, 6 个业务域分组 (`_Home`, `_Detail`, `_Auth`, `_Session`, `_Vehicle`) + `ApiBase` 基础设施 + `ApiEndpoints` 统一入口

**文件修改:**
- `packages/infrastructure/api/lib/api.dart` — 新增 line 25 导出 `export 'src/endpoints/api_endpoints.dart';`

**验证:**
- `flutter analyze packages/infrastructure/api/` — 零 error
- 仅有的 warning/info 属正常范围:
  - `unused_field` / `unused_element` — 端点已注册但尚未被消费，预期行为
  - `unnecessary_string_interpolations` — `_Session.signIn`/`signOut` 的 `'$_prefix'`，lint 级 info
  - 其余 120+ issue 为跨文件遗留 lint，与本次修改无关

**设计要点:**
- `ApiBase.baseUrl` 引用 `HttpConstant.IsRelease`/`Http_Host`（环境感知 HTTPS）
- `@[:[_Session.signIn]]` 和 `@[:[_Session.signOut]]` 共享同一路径 `/session`（后端如此设计）
- 私有分组类 (`_Home`, `_Auth` 等) 通过 `ApiEndpoints` 静态 const 暴露统一入口
