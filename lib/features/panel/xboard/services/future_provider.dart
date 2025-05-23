import 'package:hiddify/features/panel/xboard/models/invite_code_model.dart';
import 'package:hiddify/features/panel/xboard/models/user_info_model.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/invite_code_service.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/user_service.dart';
import 'package:hiddify/features/panel/xboard/utils/storage/token_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// 创建一个 FutureProvider 来管理邀请码列表
final inviteCodesProvider = FutureProvider<List<InviteCode>>((ref) async {
  final authData = await getToken(); // 使用 auth_data token
  if (authData == null) {
    throw Exception('No access token found.');
  }
  return InviteCodeService().fetchInviteCodes(authData);
});

// 定义 userInfoProvider
final userTokenInfoProvider = FutureProvider<UserInfo?>((ref) async {
  // 获取存储的访问令牌
  final loginToken = await getLoginToken(); // 使用login_token

  // 如果令牌为空，返回空值
  if (loginToken == null) {
    return null;
  }

  // 调用 AuthService 获取用户信息
  return await UserService().fetchUserInfo(loginToken);
});
