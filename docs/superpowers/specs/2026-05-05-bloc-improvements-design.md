# BLoC 最佳实践改进设计方案

> 版本：1.0  
> 日期：2026-05-05  
> 作者：Sisyphus  
> 状态：待审核

---

## 一、背景

### 1.1 当前状态

项目现有 6 个 Cubit：

| Cubit | 位置 | 职责 | State 类型 |
|-------|------|------|-----------|
| HomeCubit | feature_home | 首页数据加载 | sealed class |
| DetailCubit | feature_detail | 详情页加载 | sealed class |
| LoginCubit | feature_auth | 登录表单管理 | enum + copyWith |
| AuthCubit | auth | 认证状态管理 | enum + copyWith |
| NetworkCubit | network | 网络状态监听 | enum + copyWith |
| LocaleCubit | locale | 语言偏好管理 | enum + copyWith |

### 1.2 已识别问题

| 问题 | 影响 | 优先级 |
|------|------|--------|
| BlocObserver 缺失 | 调试效率低，无全局状态日志 | 高 |
| 测试覆盖不完整 | Detail/Auth Cubit 无单元测试 | 高 |
| State 风格不统一 | sealed class 与 enum + copyBy 并存，维护不一致 | 中 |
| LocaleCubit 启动闪烁 | 构造函数异步加载，启动瞬间闪默认语言 | 高 |
| HomeLoaded Map 可变性 | `Map<String, dynamic>` 可变，隐含 bug 风险 | 低 |

---

## 二、改进范围

### 2.1 本次改进内容

| 改进项 | 类别 | 工时 |
|--------|------|------|
| BlocObserver 添加 | 甲类（速成） | ≤1时 |
| 测试补缺（Detail/Auth） | 甲类（速成） | ≤1时 |
| freezed 引入（LocaleState） | 乙类（中等） | 2时 |
| bloc_concurrency 预集成 | 乙类（中等） | 0.5时 |
| hydrated_bloc 引入（LocaleCubit） | 丙类（架构） | 2时 |
| replay_bloc 预集成 | 乙类（中等） | 0.5时 |
| 迁移文档编写 | 甲类（速成） | 1时 |

**总工时**：约 6 小时

### 2.2 不纳入范围（留后续 PR）

| 改进项 | 原因 |
|--------|------|
| sealed class 统一（Login/Auth/Network） | 重构破坏现有 switch 代码，隔离变更 |
| AuthCubit hydrated_bloc 迁移 | 需考虑 Token 过期/安全策略，单独处理 |
| HomeLoaded Map 不可变性 | 当前无实际 bug，低优先级 |

---

## 三、依赖变更

### 3.1 新增依赖

```yaml
dependencies:
  # ===== 状态管理 =====
  flutter_bloc: ^9.1.1      # Bloc 状态管理核心
  hydrated_bloc: ^9.1.0     # 状态持久化（LocaleCubit 用）
  replay_bloc: ^9.0.0       # undo/redo 支持（预集成，当前不用）
  bloc_concurrency: ^0.2.0  # 并发控制（防快速连续 emit）
  
  # ===== 代码生成 =====
  freezed_annotation: ^2.4.0 # 不可变模型注解（LocaleState 用）
  
  # ===== 存储 =====
  hive_ce: ^2.0.0           # hydrated_bloc 底层存储（自动引入）

dev_dependencies:
  # ===== 代码生成 =====
  freezed: ^2.4.0            # freezed 代码生成器
  build_runner: ^2.4.0       # 代码生成工具
```

### 3.2 依赖用途说明

| 依赖 | 当前用途 | 未来用途 |
|------|---------|---------|
| hydrated_bloc | LocaleCubit 持久化 | AuthCubit（可选） |
| replay_bloc | 无（预集成） | 编辑器/表单撤销 |
| bloc_concurrency | 无（预集成） | 搜索输入/下拉刷新 |
| freezed | LocaleState | 新增 State 类 |

---

## 四、BlocObserver 设计

### 4.1 文件位置

`lib/core/bloc/app_bloc_observer.dart`

### 4.2 功能

| 功能 | 说明 |
|------|------|
| onCreate | 打印 Cubit 创建日志 |
| onEvent | 打印事件日志（Bloc 用） |
| onTransition | 打印状态变化日志 |
| onError | 捕获错误，打印堆栈 |

### 4.3 代码示例

```dart
import 'package:flutter_bloc/flutter_bloc.dart';

/// 全局 Bloc 观察者
///
/// 职责：打印状态变化日志，捕获异常
/// 使用：main.dart 启动前注册
class AppBlocObserver extends BlocObserver {
  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
    debugPrint('[BlocObserver] onCreate: ${bloc.runtimeType}');
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    debugPrint('[BlocObserver] ${bloc.runtimeType}: ${transition.currentState} → ${transition.nextState}');
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    debugPrint('[BlocObserver] ${bloc.runtimeType} ERROR: $error');
    debugPrint(stackTrace.toString());
  }
}
```

### 4.4 注册位置

`lib/main.dart`：

```dart
void main() {
  Bloc.observer = AppBlocObserver();
  // 其他初始化...
  runApp(App());
}
```

---

## 五、测试补缺设计

### 5.1 新增测试文件

| 文件 | 位置 | 测试内容 |
|------|------|---------|
| detail_cubit_test.dart | packages/features/feature_detail/test/ | DetailCubit loadData 成功/失败 |
| auth_cubit_test.dart | packages/services/auth/test/ | AuthCubit login/logout 成功/失败 |

### 5.2 测试模式

沿用现有 `home_cubit_test.dart` 风格：

- `blocTest` 包测试
- `mocktail` Mock Repository
- 成功/失败双场景覆盖

### 5.3 代码示例（detail_cubit_test.dart）

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:feature_detail/feature_detail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDetailRepository extends Mock implements DetailRepository {}

void main() {
  late MockDetailRepository mockRepo;

  setUp(() {
    mockRepo = MockDetailRepository();
  });

  group('DetailCubit', () {
    blocTest<DetailCubit, DetailState>(
      'loadData 成功时发出 [loading, loaded]',
      build: () {
        when(() => mockRepo.getDetailData(any()))
          .thenAnswer((_) async => {'id': '123', 'title': '测试'});
        return DetailCubit(mockRepo);
      },
      act: (cubit) => cubit.loadData('123'),
      expect: () => [
        isA<DetailLoading>(),
        isA<DetailLoaded>(),
      ],
    );

    blocTest<DetailCubit, DetailState>(
      'loadData 失败时发出 [loading, error]',
      build: () {
        when(() => mockRepo.getDetailData(any()))
          .thenThrow(Exception('加载失败'));
        return DetailCubit(mockRepo);
      },
      act: (cubit) => cubit.loadData('123'),
      expect: () => [
        isA<DetailLoading>(),
        isA<DetailError>(),
      ],
    );
  });
}
```

---

## 六、freezed 引入设计

### 6.1 应用范围

**仅 LocaleState**（本次改进）

后续新增 State 类可按需使用 freezed。

### 6.2 LocaleState 改造

**改前（手写）**：

```dart
class LocaleState extends Equatable {
  final Locale locale;
  const LocaleState({required this.locale});
  
  LocaleState copyWith({Locale? locale}) {
    return LocaleState(locale: locale ?? this.locale);
  }
  
  @override
  List<Object?> get props => [locale];
}
```

**改后（freezed）**：

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'locale_state.freezed.dart';

@freezed
class LocaleState with _$LocaleState {
  const factory LocaleState({
    required Locale locale,
  }) = _LocaleState;
}
```

### 6.3 代码生成命令

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 七、hydrated_bloc 迁移设计

### 7.1 应用范围

**仅 LocaleCubit**（本次迁移）

理由：
- 解决启动闪烁问题（核心收益）
- AuthCubit 需单独处理（Token 过期/安全策略）

### 7.2 迁移步骤

1. pubspec.yaml 加依赖（hydrated_bloc）
2. main.dart 初始化 HydratedStorage
3. LocaleCubit 改 HydratedCubit
4. LocaleState 改 freezed sealed class
5. 实现 fromJson/toJson
6. DI 注册改（移除 KeyValueStorage 注入）
7. 加 storagePrefix 硬编码

### 7.3 启动初始化

**lib/main.dart**：

```dart
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // HydratedBloc 存储初始化
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: await getApplicationDocumentsDirectory(),
  );
  
  // BlocObserver 注册
  Bloc.observer = AppBlocObserver();
  
  // DI 初始化
  await setupDependencies();
  
  runApp(App());
}
```

### 7.4 LocaleCubit 改造

**改前**：

```dart
class LocaleCubit extends Cubit<LocaleState> {
  final KeyValueStorage _storage;
  static const String _localeKey = 'app_locale';
  
  LocaleCubit(this._storage) : super(LocaleState(locale: Locale('zh'))) {
    _loadSavedLocale();  // 异步加载，可能闪烁
  }
  
  Future<void> _loadSavedLocale() async {
    final savedLocale = await _storage.getString(_localeKey);
    if (savedLocale != null) {
      emit(LocaleState(locale: Locale(savedLocale)));
    }
  }
  
  Future<void> setLocale(Locale locale) async {
    await _storage.putString(_localeKey, locale.languageCode);
    emit(LocaleState(locale: locale));
  }
}
```

**改后**：

```dart
import 'package:hydrated_bloc/hydrated_bloc.dart';

/// 语言管理 Cubit
///
/// 使用 hydrated_bloc 实现状态持久化
/// 启动时同步恢复，无闪烁
class LocaleCubit extends HydratedCubit<LocaleState> {
  /// storagePrefix 硬编码（防止代码混淆后键名变化）
  static const String _storagePrefix = 'LocaleCubit';
  
  LocaleCubit() : super(LocaleState(locale: Locale('zh')));
  
  @override
  String get storagePrefix => _storagePrefix;
  
  /// 从 JSON 恢复状态
  @override
  LocaleState? fromJson(Map<String, dynamic> json) {
    final localeCode = json['locale'] as String?;
    if (localeCode != null) {
      return LocaleState(locale: Locale(localeCode));
    }
    return null;  // 无缓存时用默认
  }
  
  /// 状态转 JSON 存储
  @override
  Map<String, dynamic>? toJson(LocaleState state) {
    return {'locale': state.locale.languageCode};
  }
  
  /// 设置语言
  /// 
  /// emit 自动持久化，无需手动 save
  Future<void> setLocale(Locale locale) async {
    emit(LocaleState(locale: locale));
  }
  
  /// 重置为默认语言
  Future<void> resetToDefault() async {
    emit(LocaleState(locale: Locale('zh')));
  }
}
```

### 7.5 DI 注册改造

**改前**：

```dart
// packages/services/locale/lib/src/di/setup.dart
void setupLocale(ServiceLocator sl) {
  sl.registerSingleton<LocaleCubit>(
    () => LocaleCubit(sl<KeyValueStorage>()),
  );
}
```

**改后**：

```dart
void setupLocale(ServiceLocator sl) {
  sl.registerSingleton<LocaleCubit>(
    () => LocaleCubit(),  // 无需注入 KeyValueStorage
  );
}
```

### 7.6 注意事项

| 注意项 | 说明 | 处理方式 |
|--------|------|---------|
| storagePrefix 混淆 | 代码压缩后 runtimeType 变化 | 硬编码字符串 |
| Web 部署状态丢失 | 浏览器缓存清空 | 勿依赖持久化 |
| schema 变更 | 无内置迁移 API | fromJson 中手动处理 |
| 大状态卡顿 | 同步 JSON 阻塞 | LocaleState 仅 1 字段，无风险 |

---

## 八、replay_bloc 预集成设计

### 8.1 当前状态

**预集成（仅加依赖，不启用）**

### 8.2 适用场景

| 场景 | 启用时机 |
|------|---------|
| 文本编辑器 | 新增笔记模块时 |
| 绘图标注工具 | 新增绘图功能时 |
| 多步骤表单 | 新增配置向导时 |
| 任务状态切换 | 新增任务管理时 |

### 8.3 启用步骤（未来参照）

1. 目标 Cubit 改 ReplayCubit
2. DI 注册改
3. UI 层加 undo/redo 按钮
4. 调用 `undo()`/`redo()` 方法

### 8.4 文档位置

`docs/replay_bloc-migration-guide.md`（未来编写）

---

## 九、bloc_concurrency 预集成设计

### 9.1 当前状态

**预集成（仅加依赖，不启用）**

### 9.2 适用场景

| 场景 | 启用时机 |
|------|---------|
| 搜索输入（防快速触发） | 新增搜索功能时 |
| 下拉刷新（防重复刷新） | 新增刷新逻辑时 |
| 高频按钮点击 | 新增点赞/收藏时 |

### 9.3 启用步骤（未来参照）

```dart
// 在 Bloc/Cubit 的 on<Event> 中加并发策略
on<SearchEvent>(
  _onSearch,
  transformer: droppable(),  // 丢弃重复事件
);
```

---

## 十、文档设计

### 10.1 文档结构

```
docs/
├── hydrated_bloc-migration-guide.md  # hydrated_bloc 迁移指南
├── bloc-extensions-guide.md          # bloc 扩展总览（未来）
└── replay_bloc-migration-guide.md    # replay_bloc 迁移指南（未来）
```

### 10.2 hydrated_bloc-migration-guide.md 内容大纲

```markdown
# hydrated_bloc 迁移指南

## 适用判断

### 适用场景
- 用户偏好（语言、主题）
- 认证状态（Token 过期需额外处理）
- 简单配置

### 不适用场景
- 大数据列表（性能差）
- 需加密/TTL/迁移
- 跨 isolate 共享

## 迁移步骤

1. 加依赖（hydrated_bloc）
2. 初始化 HydratedStorage（main.dart）
3. Cubit 改 HydratedCubit
4. 实现 fromJson/toJson
5. 加 storagePrefix 硬编码
6. DI 注册改（移除 KeyValueStorage）

## 代码示例

（LocaleCubit 改前改后对比）

## 注意事项

- storagePrefix 硬编码（防混淆）
- Web 部署缓存清空风险
- schema 变需手动处理

## 常见问题

- 状态闪烁？ → 检查 HydratedStorage 初始化顺序
- 数据丢失？ → 检查 storagePrefix 是否一致
- 状态未恢复？ → 检查 fromJson 返回值
```

---

## 十一、文件改动清单

### 11.1 新建文件

| 文件路径 | 说明 |
|----------|------|
| lib/core/bloc/app_bloc_observer.dart | BlocObserver 实现 |
| packages/features/feature_detail/test/detail_cubit_test.dart | DetailCubit 测试 |
| packages/services/auth/test/auth_cubit_test.dart | AuthCubit 测试 |
| docs/hydrated_bloc-migration-guide.md | 迁移文档 |

### 11.2 修改文件

| 文件路径 | 改动说明 |
|----------|---------|
| pubspec.yaml | 加依赖（带中文注释） |
| lib/main.dart | HydratedStorage 初始化 + BlocObserver 注册 |
| packages/services/locale/lib/src/locale_cubit.dart | 改 HydratedCubit |
| packages/services/locale/lib/src/locale_state.dart | 改 freezed sealed |
| packages/services/locale/lib/src/locale_state.freezed.dart | 自动生成 |
| packages/services/locale/lib/di/setup.dart | DI 注册改 |
| packages/services/locale/pubspec.yaml | 加 freezed_annotation 依赖 |

---

## 十二、验收标准

### 12.1 功能验收

| 验收项 | 验收方式 |
|--------|---------|
| BlocObserver 日志 | 运行 App，观察状态变化日志打印 |
| LocaleCubit 启动恢复 | 重启 App，语言保持上次选择，无闪烁 |
| LocaleCubit 持久化 | setLocale 后重启，状态恢复 |
| Detail/Auth 测试通过 | `flutter test` 无失败 |
| freezed 代码生成 | LocaleState.freezed.dart 生成成功 |

### 12.2 质量验收

| 验收项 | 验收方式 |
|--------|---------|
| 无编译错误 | `flutter analyze` 通过 |
| 无运行错误 | App 启动无崩溃 |
| 测试覆盖 | Detail/Auth Cubit 测试覆盖 100% |
| 文档完整 | 迁移指南包含全部步骤 |

---

## 十三、风险评估

### 13.1 技术风险

| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|---------|
| HydratedStorage 初始化失败 | 低 | 高 | main.dart 加 await，失败打印错误 |
| freezed 生成冲突 | 低 | 中 | build_runner --delete-conflicting-outputs |
| storagePrefix 混淆 | 中 | 高 | 硬编码字符串，文档提醒 |
| Web 部署状态丢失 | 中 | 低 | 文档说明，勿依赖持久化 |

### 13.2 业务风险

| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|---------|
| LocaleCubit 改动影响现有功能 | 低 | 中 | 充分测试，保持 API 不变 |
| DI 注册改动影响启动 | 低 | 高 | 启动流程完整测试 |

---

## 十四、后续计划

### 14.1 本次改进完成后

| 任务 | 时间 |
|------|------|
| sealed class 统一（Login/Auth/Network） | 后续 PR |
| AuthCubit hydrated_bloc 迁移 | 后续 PR（需 Token 过期策略） |
| HomeLoaded Map 不可变性 | 后续 PR |

### 14.2 bloc 扩展启用时机

| 扩展 | 启用触发条件 |
|------|-------------|
| replay_bloc | 新增编辑器/表单撤销功能 |
| bloc_concurrency | 新增搜索/下拉刷新功能 |

---

## 十五、附录

### 15.1 依赖版本兼容表

| 依赖 | 版本 | 与 flutter_bloc 兼容 |
|------|------|---------------------|
| flutter_bloc | 9.1.1 | - |
| hydrated_bloc | 9.1.0 | ✅ |
| replay_bloc | 9.0.0 | ✅ |
| bloc_concurrency | 0.2.0 | ✅ |
| freezed | 2.4.0 | 无关（纯 Dart） |

### 15.2 参考资源

| 资源 | 链接 |
|------|------|
| bloc 官方文档 | bloclibrary.dev |
| hydrated_bloc 文档 | pub.dev/packages/hydrated_bloc |
| freezed 文档 | pub.dev/packages/freezed |
| bloc_concurrency 文档 | pub.dev/packages/bloc_concurrency |
| replay_bloc 文档 | pub.dev/packages/replay_bloc |

---

**文档状态**：待用户审核

**下一步**：用户审核后 → writing-plans skill → 实施计划