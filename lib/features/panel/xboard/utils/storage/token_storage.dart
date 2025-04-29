import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

// 统一定义token的key
const String _authDataKey = 'auth_data';
const String _loginTokenKey = 'login_token';

Future<void> _writeLog(String message) async {
  final now = DateTime.now().toString().split('.').first;
  final logLine = '[TokenStorage] $now: $message\n';
  try {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/app_login.log');
    await file.writeAsString(logLine, mode: FileMode.append);
  } catch (e) {}
}

Future<void> storeToken(String? token) async {
  if (token == null) return;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_authDataKey, token);
  await _writeLog('Stored auth_data token: $token');
}

Future<String?> getToken() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_authDataKey);
    await _writeLog('Retrieved auth_data token: ${token ?? 'null'}');
    return token;
  } catch (e) {
    await _writeLog('Error getting auth_data token: $e');
    return null;
  }
}

Future<void> deleteToken() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_authDataKey);
  await _writeLog('Deleted auth_data token');
}

Future<void> storeLoginToken(String? token) async {
  if (token == null) return;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_loginTokenKey, token);
  await _writeLog('Stored login_token: $token');
}

Future<String?> getLoginToken() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_loginTokenKey);
    await _writeLog('Retrieved login_token: ${token ?? 'null'}');
    return token;
  } catch (e) {
    await _writeLog('Error getting login_token: $e');
    return null;
  }
}

Future<Map<String, String>?> getSavedCredentials() async {
  final prefs = await SharedPreferences.getInstance();
  final email = prefs.getString('saved_username');
  final password = prefs.getString('saved_password');
  if (email != null && password != null) {
    return {'email': email, 'password': password};
  }
  return null;
}

Future<void> saveToken(String token) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_authDataKey, token);
    await _writeLog('Saved auth_data token: $token');
  } catch (e) {
    await _writeLog('Error saving auth_data token: $e');
  }
}

Future<void> saveLoginToken(String token) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_loginTokenKey, token);
    await _writeLog('Saved login_token: $token');
  } catch (e) {
    await _writeLog('Error saving login_token: $e');
  }
}

Future<void> clearTokens() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authDataKey);
    await prefs.remove(_loginTokenKey);
    await _writeLog('Cleared all tokens');
  } catch (e) {
    await _writeLog('Error clearing tokens: $e');
  }
}
