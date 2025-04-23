# Panel 模块分析

## 1. 模块概述
Panel 模块是 Hiddify 应用中的面板管理模块，主要负责用户认证、订阅管理、支付处理等功能。该模块基于 MVVM 架构设计，使用 Riverpod 进行状态管理。

## 2. 目录结构
```
lib/features/panel/
└── xboard/                    # XBoard 面板实现
    ├── views/                 # 视图层
    │   ├── components/        # 可复用组件
    │   ├── domain_check_indicator.dart    # 域名检查指示器
    │   ├── forget_password_view.dart      # 忘记密码页面
    │   ├── login_view.dart                # 登录页面
    │   ├── purchase_page.dart             # 购买页面
    │   ├── register_view.dart             # 注册页面
    │   └── user_info_page.dart            # 用户信息页面
    │
    ├── viewmodels/            # 视图模型层
    │   ├── login_viewmodel/   # 登录视图模型
    │   ├── dialog_viewmodel/  # 对话框视图模型
    │   ├── account_balance_viewmodel.dart  # 账户余额视图模型
    │   ├── domain_check_viewmodel.dart     # 域名检查视图模型
    │   ├── purchase_viewmodel.dart         # 购买视图模型
    │   ├── reset_subscription_viewmodel.dart # 重置订阅视图模型
    │   └── user_info_viewmodel.dart        # 用户信息视图模型
    │
    ├── services/              # 服务层
    │   ├── http_service/      # HTTP 服务
    │   │   ├── auth_service.dart           # 认证服务
    │   │   ├── balance_service.dart        # 余额服务
    │   │   ├── domain_service.dart         # 域名服务
    │   │   ├── http_service.dart           # HTTP 基础服务
    │   │   ├── invite_code_service.dart    # 邀请码服务
    │   │   ├── order_service.dart          # 订单服务
    │   │   ├── payment_service.dart        # 支付服务
    │   │   ├── plan_service.dart           # 套餐服务
    │   │   ├── subscription_service.dart   # 订阅服务
    │   │   └── user_service.dart           # 用户服务
    │   ├── auth_provider.dart              # 认证提供者
    │   ├── future_provider.dart            # 异步数据提供者
    │   ├── monitor_pay_status.dart         # 支付状态监控
    │   ├── purchase_service.dart           # 购买服务
    │   └── subscription.dart               # 订阅管理
    │
    └── models/                # 数据模型层
        ├── invite_code_model.dart          # 邀请码模型
        ├── order_model.dart                # 订单模型
        ├── plan_model.dart                 # 套餐模型
        ├── purchase_detail_model.dart      # 购买详情模型
        └── user_info_model.dart            # 用户信息模型
```

## 3. 核心功能

### 3.1 用户认证
- **登录/注册**
  - 视图：`login_view.dart`, `register_view.dart`
  - 服务：`auth_service.dart`
  - 模型：`user_info_model.dart`

- **密码管理**
  - 视图：`forget_password_view.dart`
  - 服务：`auth_service.dart`

### 3.2 订阅管理
- **订阅状态**
  - 服务：`subscription.dart`, `subscription_service.dart`
  - 视图模型：`reset_subscription_viewmodel.dart`

- **套餐购买**
  - 视图：`purchase_page.dart`
  - 视图模型：`purchase_viewmodel.dart`
  - 服务：`purchase_service.dart`, `plan_service.dart`
  - 模型：`plan_model.dart`, `purchase_detail_model.dart`

### 3.3 支付系统
- **订单管理**
  - 服务：`order_service.dart`, `payment_service.dart`
  - 模型：`order_model.dart`
  - 监控：`monitor_pay_status.dart`

- **余额管理**
  - 视图模型：`account_balance_viewmodel.dart`
  - 服务：`balance_service.dart`

### 3.4 用户管理
- **用户信息**
  - 视图：`user_info_page.dart`
  - 视图模型：`user_info_viewmodel.dart`
  - 服务：`user_service.dart`

- **邀请系统**
  - 服务：`invite_code_service.dart`
  - 模型：`invite_code_model.dart`

## 4. 关键实现

### 4.1 HTTP 服务
- 基础服务：`http_service.dart`
- 认证处理：`auth_service.dart`
- 错误处理：统一的错误处理机制
- 请求拦截：认证令牌管理

### 4.2 状态管理
- 使用 Riverpod 进行状态管理
- 异步数据处理：`future_provider.dart`
- 认证状态：`auth_provider.dart`

### 4.3 支付流程
1. 选择套餐
2. 创建订单
3. 发起支付
4. 监控支付状态
5. 更新订阅

## 5. 注意事项

### 5.1 代码修改
1. **视图层修改**
   - 位置：`views/` 目录
   - 注意：保持 UI 一致性，遵循现有设计模式

2. **业务逻辑修改**
   - 位置：`services/` 和 `viewmodels/` 目录
   - 注意：保持状态管理的一致性

3. **API 修改**
   - 位置：`services/http_service/` 目录
   - 注意：保持错误处理机制

### 5.2 最佳实践
1. 遵循 MVVM 架构
2. 使用 Riverpod 进行状态管理
3. 实现适当的错误处理
4. 保持代码风格一致
5. 添加必要的注释和文档

## 6. 常见问题

### 6.1 认证问题
- 检查 `auth_service.dart` 中的认证逻辑
- 验证 `auth_provider.dart` 中的状态管理

### 6.2 支付问题
- 检查 `payment_service.dart` 中的支付逻辑
- 验证 `monitor_pay_status.dart` 中的状态监控

### 6.3 订阅问题
- 检查 `subscription.dart` 中的订阅管理
- 验证 `subscription_service.dart` 中的服务调用 