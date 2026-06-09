# Coverage Guide

## 概述

项目使用 `flutter test --coverage` 生成 lcov 格式覆盖率报告，支持本地 HTML 查看和 CI 自动上传到 codecov.io。

**覆盖率门槛**: 80%（CI 强制，低于此值 PR 不可合并）

## 双轨报告

| 方式 | 用途 | 触发 |
|------|------|------|
| codecov.io | CI 自动，PR 评论显示覆盖率变化 | push/PR to main |
| 本地 HTML | 开发时逐行查看覆盖详情 | `make coverage-local` |

## CI 流程

PR 自动触发 `.github/workflows/coverage.yml`：

```
melos test:coverage → check_coverage.sh 80 → codecov upload → artifact
```

- `check_coverage.sh 80`: 合并所有包的 lcov.info，计算行覆盖率，低于 80% 则 CI 失败
- codecov 评论会显示与 base 分支的覆盖率差异
- artifact 保留 7 天，可下载原始 lcov.info

## 本地使用

```bash
# 方式 1: 一键生成 HTML 报告
make coverage-local

# 方式 2: 分步执行
melos test:coverage            # 生成所有 lcov.info
./scripts/coverage_local.sh    # 合并 + 生成 HTML

# 方式 3: 只检查覆盖率是否达标
./scripts/check_coverage.sh 80  # 传参设置最低百分比
```

HTML 报告输出到 `coverage/html/index.html`，浏览器打开即可逐行查看。

## 覆盖率排除规则

以下文件自动排除（通过 lcov --remove）：
- `*.g.dart` — 代码生成文件
- `*.freezed.dart` — freezed 生成文件
- `*.config.dart` — injectable/build_runner 生成文件
- `test/**` — 测试文件本身
- `lib/gen/**` — flutter_gen 生成文件

## 覆盖率目标

| 层级 | 目标 | 说明 |
|------|------|------|
| domain/usecases | 100% | 纯逻辑，必须全覆盖 |
| domain/models | 90%+ | 含 copyWith/equals |
| services/cubit | 80%+ | bloc_test 覆盖状态流转 |
| features | 70%+ | 核心路径覆盖 |
| infrastructure | 60%+ | 重点测拦截器/缓存策略 |

## 提升覆盖率的技巧

1. **Cubit 测试**: 用 `bloc_test` 包的 `blocTest()` 宏，一行测一个状态转换
2. **Repository 测试**: 用 `mocktail` mock Dio 返回值
3. **UseCase 测试**: 纯函数，直接测输入输出
4. **排除生成代码**: 确保 lcov 过滤规则正确，不被生成代码拉低

## 安装 lcov

macOS: `brew install lcov`
Linux: `sudo apt-get install lcov`
CI (ubuntu-latest): 已预装

## 常见问题

**Q: 为什么覆盖率突然下降？**
A: 新增了大量代码但没补测试，或新增了生成文件没被排除。

**Q: 本地通过但 CI 失败？**
A: CI 用 `melos test:coverage` 跑全量测试，本地可能只跑了部分包。用 `melos test:coverage` 确保全量。
