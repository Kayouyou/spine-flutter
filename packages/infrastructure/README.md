# infrastructure 目录

存放纯技术基础设施包（无业务逻辑）。

## 目录下有哪些包

- api/ - HTTP 网络请求
- routing/ - 路由导航
- key_value_storage/ - 本地存储
- component_library/ - UI 组件库（theme + constants）

## 判断标准

问自己："这个包知道业务是什么吗？"

- 知道"用户、商品、订单" -> 不放这里（放 domain 或 services）
- 只知道"HTTP、路由、存储、UI" -> 放这里

## 与其他层的关系

infrastructure 不依赖任何业务层
infrastructure 被 domain、services、features 依赖

## 约定

- 无业务逻辑
- 无业务数据模型
- 可被任何上层依赖
- 独立测试（不依赖业务）