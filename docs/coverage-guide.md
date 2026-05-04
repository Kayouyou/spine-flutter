# Coverage Guide

## 双轨报告

| 方式 | 用途 |
|------|------|
| codecov.io | CI 自动，PR 可见 |
| 本地 HTML | 无网络依赖 |

## CI 使用

PR 自动触发 `.github/workflows/coverage.yml`，结果：
- codecov 评论显示覆盖率变化
- artifact 可下载 HTML

## 本地生成

```bash
make coverage-local
# 或
./scripts/coverage_local.sh
```

## 覆盖率目标

- Phase 1: usecases 100%
- Phase 2: models/exceptions 按实际
- 全项目: 逐步提升

## 安装 lcov

macOS: `brew install lcov`
Linux: `sudo apt-get install lcov`
