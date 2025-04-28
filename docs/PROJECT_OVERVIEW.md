# Hiddify 项目概述

## 1. 项目简介
Hiddify 是一个跨平台的多协议代理前端应用，支持 Windows、Linux、macOS、iOS 和 Android 平台。该项目基于 Flutter 框架开发，使用 Singbox 作为核心代理引擎。当前版本为 1.1.2+20507。

## 2. 技术栈
### 2.1 主要框架和库
- **Flutter**: 跨平台 UI 框架 (>=3.24.0 <=3.24.3)
- **Riverpod**: 状态管理 (hooks_riverpod: ^2.4.10)
- **Freezed**: 不可变数据模型 (freezed: ^2.4.7)
- **Flutter Hooks**: 状态管理增强 (flutter_hooks: ^0.20.5)
- **GoRouter**: 路由管理 (go_router: ^13.2.0)
- **Drift**: 数据库管理 (drift: ^2.16.0)
- **Dio**: HTTP 客户端 (dio: ^5.4.1)
- **Singbox**: 核心代理引擎
- **Slang**: 国际化支持 (slang: ^3.30.1)
- **FPDart**: 函数式编程工具 (fpdart: ^1.1.0)
- **RxDart**: 响应式编程 (rxdart: ^0.27.7)

### 2.2 开发工具
- **build_runner**: 代码生成 (build_runner: ^2.4.8)
- **ffigen**: C/C++ 绑定生成 (ffigen: ^8.0.2)
- **lint**: 代码检查 (lint: ^2.3.0)
- **json_serializable**: JSON 序列化 (json_serializable: ^6.7.1)
- **slang_build_runner**: 国际化代码生成 (slang_build_runner: ^3.30.0)
- **flutter_gen_runner**: 资源代码生成 (flutter_gen_runner: ^5.4.0)

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
│   ├── widget/     # 通用组件
│   ├── haptic/     # 触觉反馈
│   └── directories/# 目录管理
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
│   ├── window/     # 窗口管理
│   ├── per_app_proxy/ # 应用代理
│   ├── geo_asset/  # 地理位置资源
│   ├── deep_link/  # 深度链接
│   ├── config_option/ # 配置选项
│   ├── common/     # 公共组件
│   ├── app_update/ # 应用更新
│   ├── intro/      # 引导页
│   └── shortcut/   # 快捷键
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
   - 性能优化

2. **用户界面**
   - 响应式设计
   - 多语言支持
   - 主题切换
   - 系统托盘集成
   - 触觉反馈

3. **数据管理**
   - 本地数据库 (Drift)
   - 配置文件管理
   - 用户偏好设置
   - 缓存管理

4. **网络功能**
   - HTTP 客户端 (Dio)
   - API 集成
   - 代理配置同步
   - 错误重试机制

5. **系统集成**
   - 开机自启
   - 系统托盘
   - 通知中心
   - 深色模式
   - 快捷键支持

## 4. 主要功能
1. **代理管理**
   - 多协议支持
   - 自动切换
   - 连接状态监控
   - 流量统计
   - 应用级代理

2. **用户系统**
   - 登录/注册
   - 密码恢复
   - 订阅管理
   - 支付集成
   - 用户信息管理

3. **系统集成**
   - 开机自启
   - 系统托盘
   - 通知中心
   - 深色模式
   - 快捷键支持
   - 深度链接

4. **本地化**
   - 支持多语言
   - 自动切换
   - 时区支持
   - 地理位置识别

5. **其他功能**
   - 应用更新
   - 引导页
   - 日志管理
   - 统计分析
   - 错误报告

## 5. API 集成
1. **面板 API**
   - 用户认证
   - 订阅管理
   - 支付处理
   - 统计信息
   - 配置同步

2. **支付平台 API**
   - 支付处理
   - 订单管理
   - 退款处理
   - 余额查询

3. **系统 API**
   - 系统托盘
   - 通知中心
   - 窗口管理
   - 文件系统

## 6. 开发指南
### 6.1 代码规范
- 使用 Riverpod 进行状态管理
- 遵循 Flutter 最佳实践
- 使用 Freezed 生成不可变数据模型
- 实现适当的错误处理
- 添加必要的注释和文档

### 6.2 构建流程
1. 准备依赖
   ```bash
   flutter pub get
   ```

2. 生成代码
   ```bash
   flutter pub run build_runner build
   ```

3. 运行项目
   ```bash
   flutter run
   ```

4. 构建应用
   ```bash
   flutter build [platform]
   ```

## 7. 注意事项
1. 避免修改框架底层代码
2. 遵循现有架构模式
3. 保持代码风格一致
4. 添加适当的注释和文档
5. 进行充分的测试
6. 注意跨平台兼容性
7. 遵循安全最佳实践

## 8. 常见修改位置
1. **UI 修改**
   - `lib/features/[feature]/view/`
   - `lib/core/widget/`
   - `lib/features/common/`

2. **业务逻辑**
   - `lib/features/[feature]/provider/`
   - `lib/features/[feature]/service/`
   - `lib/core/utils/`

3. **数据模型**
   - `lib/core/model/`
   - `lib/features/[feature]/model/`
   - `lib/singbox/model/`

4. **API 集成**
   - `lib/core/http_client/`
   - `lib/features/[feature]/api/`
   - `lib/singbox/service/`

5. **本地化**
   - `lib/core/localization/`
   - `assets/translations/`
   - `project.inlang/` 