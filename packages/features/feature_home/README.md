# feature_home 包

首页功能模块。

## 内部结构

- cubit/ - HomeCubit 状态管理
- repository/ - 数据获取
- ui/ - 页面 Widget
- di/ - DI 自注册
- models/ - 页面特定数据模型

## 注册方式

- HomeCubit: Factory（页面级）
- HomeRepository: Factory