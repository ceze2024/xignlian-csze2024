import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _tokenKey = 'auth_token';
const String _loginTokenKey = 'login_token';

Future<void> storeToken(String token) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_tokenKey, token);
  if (kDebugMode) {
    print('Token stored: $token');
  }
}

Future<String?> getToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_tokenKey);
}

Future<void> deleteToken() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_tokenKey);
}

Future<void> storeLoginToken(String token) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_loginTokenKey, token);
}

Future<String?> getLoginToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_loginTokenKey);
}
