# Hiddify 项目概述

## 1. 项目简介
Hiddify 是一个跨平台的多协议代理前端应用，支持 Windows、Linux、macOS、iOS 和 Android 平台。该项目基于 Flutter 框架开发，使用 Singbox 作为核心代理引擎。

## 2. 技术栈
### 2.1 主要框架和库
- **Flutter**: 跨平台 UI 框架
- **Riverpod**: 状态管理
- **Freezed**: 不可变数据模型
- **Flutter Hooks**: 状态管理增强
- **GoRouter**: 路由管理
- **Drift**: 数据库管理
- **Dio**: HTTP 客户端
- **Singbox**: 核心代理引擎

### 2.2 开发工具
- **build_runner**: 代码生成
- **ffigen**: C/C++ 绑定生成
- **lint**: 代码检查
- **json_serializable**: JSON 序列化

## 3. 项目架构
### 3.1 目录结构
```
lib/
├── core/           # 核心功能模块
│   ├── analytics/  # 分析
│   ├── app_info/   # 应用信息
│   ├── database/   # 数据库
│   ├── directories/# 目录管理
│   ├── http_client/# HTTP 客户端
│   ├── localization/# 本地化
│   ├── logger/     # 日志
│   ├── model/      # 数据模型
│   ├── notification/# 通知
│   ├── preferences/# 偏好设置
│   ├── router/     # 路由
│   ├── theme/      # 主题
│   ├── utils/      # 工具类
│   └── widget/     # 通用组件
├── features/       # 功能模块
│   ├── app/        # 应用设置
│   ├── auto_start/ # 开机自启
│   ├── connection/ # 连接管理
│   ├── home/       # 主页
│   ├── log/        # 日志
│   ├── panel/      # 面板
│   ├── profile/    # 配置文件
│   ├── proxy/      # 代理设置
│   ├── settings/   # 设置
│   ├── stats/      # 统计
│   ├── system_tray/# 系统托盘
│   └── window/     # 窗口管理
└── singbox/        # Singbox 核心
    ├── generated/  # 生成的代码
    ├── model/      # 数据模型
    └── service/    # 服务
```

### 3.2 核心功能模块
1. **代理核心 (Singbox)**
   - 多协议支持
   - 代理配置管理
   - 连接状态监控

2. **用户界面**
   - 响应式设计
   - 多语言支持
   - 主题切换
   - 系统托盘集成

3. **数据管理**
   - 本地数据库
   - 配置文件管理
   - 用户偏好设置

4. **网络功能**
   - HTTP 客户端
   - API 集成
   - 代理配置同步

## 4. 主要功能
1. **代理管理**
   - 多协议支持
   - 自动切换
   - 连接状态监控
   - 流量统计

2. **用户系统**
   - 登录/注册
   - 密码恢复
   - 订阅管理
   - 支付集成

3. **系统集成**
   - 开机自启
   - 系统托盘
   - 通知中心
   - 深色模式

4. **本地化**
   - 支持多语言
   - 自动切换
   - 时区支持

## 5. API 集成
1. **面板 API**
   - 用户认证
   - 订阅管理
   - 支付处理
   - 统计信息

2. **支付平台 API**
   - 支付处理
   - 订单管理
   - 退款处理

## 6. 开发指南
### 6.1 代码规范
- 使用 Riverpod 进行状态管理
- 遵循 Flutter 最佳实践
- 使用 Freezed 生成不可变数据模型
- 实现适当的错误处理

### 6.2 构建流程
1. 准备依赖
   ```bash
   make [platform]-prepare
   ```

2. 运行项目
   ```bash
   flutter run
   ```

3. 构建应用
   ```bash
   flutter build [platform]
   ```

## 7. 注意事项
1. 避免修改框架底层代码
2. 遵循现有架构模式
3. 保持代码风格一致
4. 添加适当的注释和文档
5. 进行充分的测试

## 8. 常见修改位置
1. **UI 修改**
   - `lib/features/[feature]/view/`
   - `lib/core/widget/`

2. **业务逻辑**
   - `lib/features/[feature]/provider/`
   - `lib/features/[feature]/service/`

3. **数据模型**
   - `lib/core/model/`
   - `lib/features/[feature]/model/`

4. **API 集成**
   - `lib/core/http_client/`
   - `lib/features/[feature]/api/`

5. **本地化**
   - `lib/core/localization/`
   - `assets/translations/` 