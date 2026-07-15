# 开发效率优化建议 · 结合当前项目评审

> 日期:2026-07-15
> 类型:评审建议(**不改代码**,仅出方案与优先级)
> 范围:针对团队提出的 14 项高频开发痛点,逐条对照 `spine_flutter` 脚手架现状,给出「已具备 / 待加强 / 缺失」判定与优化建议。
> 方法:所有判定基于**实际代码抽样**(文件路径与类名可追溯),而非假设。

---

## 0. 一句话结论

`spine_flutter` 的架构骨架**成熟度远高于 14 点清单的平均预期**——路由、错误处理、多环境、DI、UseCase、日志、启动编排、缓存迁移框架、设计令牌**均已具备**。真正的优化杠杆不在"从零搭建",而在**打通两处被忽视的断点**:

1. **P0 — 自适应基准断裂**:令牌文件已用 `flutter_screenutil` 的 `.sp`/`.r`,但全仓**找不到 `ScreenUtilInit` 初始化**,`designSize` 从未声明。等于"用了自适应 API,却没设基准",实际跑在插件默认 `360×690` 上,与设计稿无关。
2. **P0 — 令牌与主题脱节**:`AppColors` 令牌挂进了 `ThemeData.extensions`,但 `FontSize`/`Spacing`/`AppRadius` **没有汇入 `ThemeData.textTheme`**,`app_theme.dart` 的 `textTheme` 仍是 Material 默认。"改一处、全局生效"的最后一公里没通。

其余多为**小补齐**(Cell 组件、令牌语义化组合、缓存边界规范文档)。

---

## 1. 14 点现状对照速查表

| # | 痛点 | 状态 | 现有证据(文件 / 类) | 结论 |
|---|------|:---:|------|------|
| 1 | UI 自适应 & Theme 全局管理 | 🟡 | `component_library/lib/src/theme/{app_colors,font_size,radius,spacing,shadows}.dart`;`flutter_screenutil ^5.9.0` | 令牌齐全,但**未初始化 ScreenUtil + 令牌未汇入 ThemeData** → 见 P0-1 / P0-2 |
| 2 | 常用 UI 组件封装 | 🟡 | `component_library/.../widgets/`:11 个组件(button/card/dialog/scaffold/text_field/toast/app_bar/empty_state/error_card/loading_button/section) | 主体完备,**缺 Cell 列表项** → P1-3 |
| 3 | 常用 Style 复用 | 🟡 | `AppRadius`/`AppShadows`/`Spacing`/`FontSize` 静态令牌 | 有原子令牌,**缺语义化 TextStyle 组合**(size+weight+height) → P0-2 |
| 4 | 新模块 Package 结构 | ✅ | Mason `bricks/feature`:生成 `ui/cubit/repository/di/routes` + 测试;`make create-feature` 4 步自动化 | 已有一键脚手架;命名与 `presentation/domain/data` 不同(monorepo 跨包分层)→ P2-2 |
| 5 | 新增 API 改动链路 | ✅ | Mason `bricks/api` + `bricks/model`;`make scaffold-api`;Dio+Retrofit 拦截器链;`FutureResult` | 标准链路已具备,R6 强制走接口 |
| 6 | 新增本地存储模型 | ✅ | `bricks/hive_model`;`key_value_storage`:`CacheData<T>` + **`MigrationRunner`(chain/clearOnMismatch)+ `SchemaVersionBox` + validate**;`PreferenceKey` enum(R9) | 迁移框架**已完整**;可补边界规范 → P1-4 |
| 7 | 第三方插件初始化统一 | ✅ | `lib/core/startup/launcher.dart`:`AppLauncher` 分阶段(核心→Sentry→错误→env→DI→SDK→业务→runApp)+ `StartupProfiler` | 已实现分阶段编排 |
| 8 | 路由集中化 | ✅ | `RouteModuleRegistry` 插件式注册 + go_router + `AuthGuard`(R7) | 完全符合建议方案 |
| 9 | 状态管理模板化 | ✅ | `bricks/feature` 内含 `cubit/{name}_cubit.dart` + `{name}_state.dart`(freezed) | 一键生成三件套 |
| 10 | 跨模块能力引用 | ✅ | 每包 barrel(`domain.dart`/`auth.dart`…)+ get_it DI + 接口依赖;`check_deps.sh` 强制 R1/R3/R4 | 已按接口 + barrel + DI 组织 |
| 11 | Service/Repository/UseCase 职责 | ✅ | `services/README.md` + `domain/README.md` + `usecases/README.md`(含 ADR-2026-06 保留决策) | 边界已详尽文档化 |
| 12 | 错误处理统一策略 | ✅ | `FutureResult`(Success/Failure);`ErrorReporter` 抽象(R8);Dio Error 拦截器 | 仓库层统一转换,UI 按 Failure 展示 |
| 13 | 日志与调试统一 | ✅ | `lib/core/utils/logger.dart` `AppLogger`(分级 + Tag);Alice(debug) | 已封装分级日志 + 可视化抓包 |
| 14 | 多环境配置管理 | ✅ | `EnvironmentConfig` + `--dart-define-from-file` + `env/.env.*` 三文件 + prod fail-fast(R5) | 完全符合建议方案 |

图例:✅ 已具备 · 🟡 部分具备/需加强 · ❌ 缺失

**统计:14 项中 10 项已达标(✅),4 项部分具备(🟡),0 项完全缺失。** 团队清单里的绝大多数最佳实践,脚手架已经落地。

---

## 2. 优先级化优化建议

### P0-1 · 初始化 ScreenUtil,声明设计稿基准(自适应的地基)

**问题**:`font_size.dart`(`.sp`)、`radius.dart`(`.r`)已依赖 screenutil,但:
- 全仓搜索 `ScreenUtilInit` / `designSize` → **0 命中**;
- `app.dart` 的 `MaterialApp.router` 外层无 `ScreenUtilInit` 包裹,`builder` 内也没有 `ScreenUtil.init`。

**后果**:`.sp`/`.r` 回退到插件默认 `designSize (360×690)`,而非 UI 设计稿实际尺寸。适配基准与设计稿不一致 → 不同机型上字号/圆角缩放比例是"错的但看起来能跑"。这是最隐蔽也最该先修的点。

**建议**:在 `app.dart` 用 `ScreenUtilInit(designSize: Size(<设计稿宽>, <设计稿高>), minTextAdapt: true, splitScreenMode: true, builder: (_, child) => MaterialApp.router(...))` 包裹;`designSize` 与设计团队对齐(常见 `375×812`)。补一条硬约束:"所有尺寸走令牌 / `.w`/`.h`/`.sp`/`.r`,禁止裸写绝对像素"。

### P0-2 · 令牌汇入 ThemeData,打通"改一处全局生效"

**问题**:`app_theme.dart` 的 `appLightTheme/appDarkTheme` 只 `copyWith(extensions: [AppColors.light/dark])`,**未设置 `textTheme`**,`FontSize`/`Spacing` 未进入主题;Widget 想要"语义化文字样式"(标题/正文/辅助)时无处可取,只能各自拼 `TextStyle(fontSize: FontSize.x, fontWeight: ...)`。且**无 `titleLarge`/`bodyMedium` 这类组合了 size+weight+height+color 的语义预设**。

**后果**:令牌只到"原子值"层级,没到"语义组合"层级。改字型规范仍要逐处改 `fontWeight`/`height`。团队最强调的"改一处全局生效"在文字样式上没兑现。

**建议**:
1. 新增语义化文字样式(建议做成 `ThemeExtension<AppTextStyles>` 或静态 `AppTextStyles`):`headingLarge/headingMedium/titleLarge/bodyLarge/bodyMedium/caption` 等,每个组合 `fontSize(.sp) + fontWeight + height + color(context.colors.*)`。
2. 把这套样式注入 `ThemeData.textTheme`,使 Material 组件默认也吃令牌。
3. 在 `docs/QUICK_REFERENCE.md` 与 `lib/src/theme/README.md` 增补"文字样式只用 `AppTextStyles.xxx`"约定。

### P1-3 · 补 `AppCell` 列表项组件(组件族收口)

**问题**:`component_library` 已有 11 个组件,但无通用列表项。设置页/详情页的"左图标 + 标题/副标题 + 右箭头/开关/文字"目前需各页手拼。

**建议**:新增 `app_cell.dart`,暴露 `leadingIcon` / `title` / `subtitle` / `trailing`(箭头 / `Switch` / 文本)/ `onTap`;内部统一读令牌(`Spacing`/`AppColors`/`AppTextStyles`)。与已有 `empty_state`/`error_card`/`loading_button` 一起构成完整"状态 + 列表"组件族。

### P1-4 · 补缓存三层边界规范文档(框架已在,补规范)

**现状**:迁移框架完整(`MigrationRunner` + `SchemaVersionBox` + `chain/clearOnMismatch` + `validate`),`CacheData<T>` 泛型容器也在。**缺的是规范文档**:何时 DTO 复用为缓存、何时独立 CacheModel。

**建议**:在 `docs/` 增一页《缓存模型规范》,明确:
- **DTO ⇄ Entity**:API 结构 = 业务结构时可薄映射,不一致时分离;
- **CacheModel 何时独立**:需要过期时间 / 脏标记 / 与 API 解耦时,独立建 `@HiveType` 模型 + 注册 `Migration`;
- 给一个"新增可缓存 API"的标准 5 步 checklist,挂进速查卡。

### P2-1 · 统一 `TextScaler` 与 screenutil 的字体缩放策略(消歧义)

**问题**:`app.dart:165-168` 手动 `MediaQuery(textScaler: TextScaler.linear(1.0))` 锁死系统字体缩放,同时令牌又用 `.sp`。两种"字体尺寸控制"并存,策略未文档化,易让新人困惑"到底谁说了算"。

**建议**:文档明确"系统字体缩放锁定 + 设计稿等比 `.sp`"是刻意选择及其理由(或改为尊重系统无障碍缩放,二选一并写清)。

### P2-2 · 模块结构命名对齐(可选,低优先)

**问题**:团队清单用 `presentation/domain/data` 三层命名;项目用 monorepo **跨包分层**(`features/*` 内 `ui/cubit/repository/di/routes`,domain/data 在独立包)。二者是**同一思想的不同物理组织**,并非缺陷。

**建议**:不强改。仅在 `AGENTS.md` / `README.md` 加一句映射说明:"本仓 monorepo 跨包 = Clean Architecture 分层,`ui/`≈presentation、独立 `domain` 包≈domain、`repository/` + `infrastructure/api`≈data",消除认知偏差即可。若团队坚持目录名对齐,再评估改 `bricks/feature` 模板(影响面:所有后续新模块)。

---

## 3. 优先级总览

| 优先级 | 事项 | 类型 | 影响面 |
|:---:|------|------|------|
| **P0-1** | 初始化 `ScreenUtilInit` + 声明 `designSize` | 缺陷修复 | 全 App 自适应基准 |
| **P0-2** | 令牌汇入 `ThemeData.textTheme` + 语义 `AppTextStyles` | 打通闭环 | 全局文字样式 |
| **P1-3** | 新增 `AppCell` 组件 | 补齐 | 列表类页面 |
| **P1-4** | 缓存三层边界规范文档 | 规范 | 新增缓存 API 流程 |
| **P2-1** | 统一字体缩放策略文档 | 消歧义 | 认知一致性 |
| **P2-2** | 模块结构命名映射说明 | 文档 | 新人上手 |

**建议节奏**:先做 P0-1 + P0-2(二者共同兑现"改一处全局生效",且 P0-1 是既有隐患);再顺手补 P1-3 组件与 P1-4/P2 文档。

---

## 4. 已完善项(保持,不重复造轮子)

以下 10 项团队痛点脚手架已高质量落地,建议**保持现状 + 仅补速查卡索引**,避免过度设计:

- 路由集中化(`RouteModuleRegistry` + go_router + AuthGuard)
- 错误处理统一(`FutureResult` + `ErrorReporter`)
- 多环境配置(`EnvironmentConfig` + dart-define-from-file + 三 env 文件 + prod fail-fast)
- DI / 跨模块引用(get_it + barrel + 接口 + `check_deps.sh` 强制单向)
- Service/Repository/UseCase 边界(三份 README + ADR)
- 日志(`AppLogger` 分级 + Tag + Alice)
- 插件初始化编排(`AppLauncher` 分阶段 + `StartupProfiler`)
- 模块 / API / 状态管理脚手架(Mason `feature`/`api`/`model`/`hive_model`/`usecase` 砖)
- 缓存迁移框架(`MigrationRunner` + `SchemaVersionBox` + 策略)
- 组件库主体(11 个通用组件)

---

## 5. 附录 · 关键证据索引

| 主题 | 位置 |
|------|------|
| 颜色令牌 | `packages/infrastructure/component_library/lib/src/theme/app_colors.dart`(`AppColors` ThemeExtension,15 语义色) |
| 尺寸令牌 | 同目录 `font_size.dart`(`.sp`)/ `radius.dart`(`.r`)/ `spacing.dart` / `shadows.dart` |
| 主题装配 | `lib/src/theme/app_theme.dart`(仅挂 `AppColors`,未接 textTheme) |
| 自适应缺口 | `lib/app.dart` `build()`:无 `ScreenUtilInit`;`app.dart:165-168` `TextScaler.linear(1.0)` |
| 组件库 | `packages/infrastructure/component_library/lib/src/widgets/`(11 组件,无 cell) |
| 缓存迁移 | `packages/infrastructure/key_value_storage/lib/src/migration/{migration_runner,schema_version_box}.dart` |
| 脚手架砖 | `bricks/{feature,api,api_gen_spec,hive_model,model,usecase}` |
| 硬约束/命令 | `docs/QUICK_REFERENCE.md`、`AGENTS.md` §1/§5.1 |

> 相关文档:架构评审见 `docs/plans/2026-07-14-scaffold-architecture-review-design.md`;速查卡见 `docs/QUICK_REFERENCE.md`。
