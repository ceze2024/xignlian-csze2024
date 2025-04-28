# 最近需求与修改记录

本文件用于记录近期对 Hiddify 客户端的主要需求、实现方式、涉及文件，便于后续维护和快速查阅。

---

## 1. 开机启动默认选中
- **需求**：Windows 客户端"开机启动"开关默认选中。
- **实现方式**：首次运行时自动调用开机自启逻辑，并写入标志，后续不再重复。
- **涉及文件**：
  - `lib/bootstrap.dart`
  - `lib/features/auto_start/notifier/auto_start_notifier.dart`

---

## 2. 域名初始化失败友好提示
- **需求**：OSS 域名全部不可用时，软件仍可进入主界面，并给出友好提示。
- **实现方式**：
  - 域名初始化失败时写入全局 Provider。
  - 主界面顶部显示红色横幅提示。
- **涉及文件**：
  - `lib/bootstrap.dart`
  - `lib/core/app_info/domain_init_failed_provider.dart`
  - `lib/features/home/widget/home_page.dart`

---

## 3. 登录页"记住密码"默认选中
- **需求**：登录页"记住密码"复选框默认选中。
- **实现方式**：
  - ViewModel 加载时默认 isRememberMe 为 true。
- **涉及文件**：
  - `lib/features/panel/xboard/viewmodels/login_viewmodel/login_viewmodel.dart`

---

## 4. 自动登录优化
- **需求**：
  1. 启动后如已保存账号密码且域名初始化成功，自动登录。
  2. 自动登录时有"正在自动登录..."提示，失败时有"自动登录失败，请手动登录"提示。
  3. 用户主动注销后，回到登录页不再自动登录，需手动登录。
- **实现方式**：
  - 自动登录前检测 SharedPreferences 的 user_logged_out 标志。
  - 登录成功后清除该标志，注销时设置为 true。
  - 自动登录时显示 loading/失败提示。
- **涉及文件**：
  - `lib/features/panel/xboard/views/login_view.dart`
  - `lib/features/panel/xboard/viewmodels/login_viewmodel/login_viewmodel.dart`
  - `lib/features/panel/xboard/services/auth_provider.dart`

---

## 5. Provider 全局唯一化
- **需求**：domainInitFailedProvider 等全局 Provider 需唯一、集中管理，便于多处导入。
- **实现方式**：
  - 新建 `lib/core/app_info/domain_init_failed_provider.dart`，所有用到的文件均 import 该文件。

---

如需查阅具体实现细节，可直接搜索上述文件及关键字。 