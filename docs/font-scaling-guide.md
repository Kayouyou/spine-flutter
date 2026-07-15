# 字体缩放策略指南 · Font Scaling Guide

> 本文回答一个新人常问的疑问：**「为什么 `app.dart` 里锁了 `TextScaler.linear(1.0)`，同时令牌又用 `.sp`？两者冲突吗？」**
> 结论：**不冲突，是刻意组合**。本指南固化该决策，避免误以为是 bug。

---

## 1. 决策（一句话）

**锁定系统字体缩放（不跟随操作系统字号）+ 设计稿等比 `.sp` 自适应。**

这是**有意为之**的产品选择：App 内的文字大小由设计稿决定、随屏幕尺寸等比缩放，**不接受用户系统「字体放大/缩小」设置的影响**。

---

## 2. 两个机制如何共存（不冲突）

| 机制 | 作用 | 谁控制 |
|------|------|--------|
| `flutter_screenutil` 的 `.sp` | 按「屏幕宽 / 设计宽」把设计稿字号**等比缩放**到当前设备 | 设计稿 + 设备宽度 |
| `MediaQuery(textScaler: TextScaler.linear(1.0))` | 把系统 `textScaleFactor` **锁成 1.0**，抵消系统字号设置 | `app.dart` |

关键点：`flutter_screenutil` 的 `.sp` 在默认情况下，会把「系统字体缩放倍数（textScaleFactor）」也乘进去。
如果不加锁，用户在系统里把字体调大，App 文字就会跟着变大——这通常不是我们想要的效果。

而 `app.dart` 用 `MediaQuery` 把 `textScaleFactor` 锁成 `1.0`，等于**吃掉了系统这一乘项**：

```
最终字号 = 设计稿数值 × (屏幕宽 / 设计宽) × 1.0(系统因子被锁)
```

所以两者分工明确、互不打架：
- **`.sp` 管「横向自适应」**（不同屏幕宽度下等比缩放，保持设计稿比例）。
- **`TextScaler.linear(1.0)` 管「关掉系统缩放」**（忽略系统字号设置）。

> 这正是 `app.dart` 注释里写的意图：`下方 MediaQuery 锁 textScaler=1.0 是有意为之，避免与 screenutil 的 .sp 二次缩放叠加`。

---

## 3. 代码落点

文件：`lib/app.dart`

```dart
// ScreenUtilInit 声明设计稿基准（P0-1，375×812，可随设计稿调整）
ScreenUtilInit(
  designSize: const Size(375, 812),
  minTextAdapt: true,
  splitScreenMode: true,
  builder: (context, _) => MaterialApp.router(
    ...
    builder: (context, child) {
      return EasyLoading.init()(
        context,
        NetworkBanner(
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.0), // 锁系统缩放
            ),
            child: child ?? const SizedBox(),
          ),
        ),
      );
    },
  ),
)
```

设计令牌侧：`FontSize` 令牌的尺寸值全部以 `.sp` 单位声明（如 `FontSize.title` = `20.sp`），语义样式 `AppTextStyles` 复用这些令牌。所有文字尺寸都走令牌，禁止裸写绝对像素。

---

## 4. 想要「跟随系统无障碍字号」怎么办？（当前不做）

如果未来产品要求尊重系统无障碍（老人模式/大字体），只需改 `app.dart` 这一处：

- **方案 A（完全跟随系统）**：删掉 `MediaQuery` 的 `textScaler` 覆盖，让 `.sp` 乘上系统因子。
- **方案 B（部分跟随，设上限）**：把锁值改成 `TextScaler.linear(min(MediaQuery.of(context).textScaleFactor, 1.3))`，允许放大但限制上限，避免极端字号破坏布局。

> 当前**不做**上述改动，保持「不跟随系统」的既定选择。如要变更，请同步更新本指南与 `app.dart` 注释，并回归各页面布局。

---

## 5. 反例（禁止）

- ❌ 在 `MediaQuery` 锁 `1.0` 的同时，又在某处用 `MediaQuery.of(context).textScaleFactor` 去放大字体 —— 自相矛盾。
- ❌ 文字尺寸直接写 `TextStyle(fontSize: 16)`（裸像素），绕过 `.sp` 与令牌 —— 破坏全局一致性，违反组件库约定。
- ❌ 把 `designSize` 改得和真实设计稿不一致还不更新注释 —— 会让 `.sp` 比例失真。
