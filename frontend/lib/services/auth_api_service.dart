import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';

class AuthResult {
  final bool success;
  final String? token;
  final String? errorMessage;
  final Map<String, dynamic>? userData;

  AuthResult({
    required this.success,
    this.token,
    this.errorMessage,
    this.userData,
  });
}

class AuthApiService {
  String get _baseUrl {
    String base = ApiConfig.baseUrl;
    // Tự động điều chỉnh host cho Android Emulator nếu cần
    if (!kIsWeb && Platform.isAndroid && base.contains('127.0.0.1')) {
      base = base.replaceAll('127.0.0.1', '10.0.2.2');
    }
    return base;
  }

  /// Đăng nhập tài khoản: POST /api/v1/auth/login
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/api/v1/auth/login');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email.trim(),
              'password': password,
            }),
          )
          .timeout(ApiConfig.defaultTimeout);

      final Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200 && data['success'] == true) {
        return AuthResult(
          success: true,
          token: data['access_token'] as String?,
          userData: data['data'] as Map<String, dynamic>?,
        );
      } else {
        final message = data['detail'] ?? data['message'] ?? 'Đăng nhập không thành công';
        return AuthResult(
          success: false,
          errorMessage: message.toString(),
        );
      }
    } catch (e) {
      return AuthResult(
        success: false,
        errorMessage: 'Lỗi kết nối máy chủ: $e',
      );
    }
  }

  /// Đăng ký tài khoản mới: POST /api/v1/auth/register
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/api/v1/auth/register');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': name.trim(),
              'email': email.trim(),
              'password': password,
            }),
          )
          .timeout(ApiConfig.defaultTimeout);

      final Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));

      if ((response.statusCode == 200 || response.statusCode == 201) && data['success'] == true) {
        return AuthResult(
          success: true,
          token: data['access_token'] as String?,
          userData: data['data'] as Map<String, dynamic>?,
        );
      } else {
        final message = data['detail'] ?? data['message'] ?? 'Đăng ký không thành công';
        return AuthResult(
          success: false,
          errorMessage: message.toString(),
        );
      }
    } catch (e) {
      return AuthResult(
        success: false,
        errorMessage: 'Lỗi kết nối máy chủ: $e',
      );
    }
  }

  /// Lấy thông tin user hiện tại từ token: GET /api/v1/me
  Future<Map<String, dynamic>?> getMe(String token) async {
    try {
      final url = Uri.parse('$_baseUrl/api/v1/me');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(ApiConfig.defaultTimeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data['success'] == true && data['data'] != null) {
          return data['data'] as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
