# models 目录

存放页面特定数据模型。

## 判断标准

- 核心业务数据（User、Product）→ 放 domain/models/
- 不确定是否共用 → 先放这里，发现共用再迁移
- 确定单 feature 使用 → 放这里