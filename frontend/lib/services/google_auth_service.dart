import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Dịch vụ kết nối Google Sign-In chính thức của Google (Native SDK)
/// Cho phép người dùng đăng nhập bằng tài khoản Gmail thật trên thiết bị Android/iOS.
class GoogleAuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>[
      'email',
      'https://www.googleapis.com/auth/userinfo.profile',
    ],
  );

  /// Gọi hộp thoại chọn tài khoản Google thật của hệ điều hành
  /// Trả về [GoogleSignInAccount] chứa email, displayName, photoUrl thật.
  /// Trả về `null` nếu người dùng hủy chọn tài khoản.
  static Future<GoogleSignInAccount?> signIn() async {
    try {
      // Đăng xuất phiên hiện tại trước để người dùng có thể linh hoạt chọn tài khoản khác
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
      final account = await _googleSignIn.signIn();
      return account;
    } catch (e) {
      debugPrint('[GoogleAuthService] Lỗi khi signIn Google: $e');
      rethrow;
    }
  }

  /// Đăng xuất tài khoản Google khỏi thiết bị
  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('[GoogleAuthService] Lỗi khi signOut: $e');
    }
  }

  /// Kiểm tra xem người dùng hiện tại đã đăng nhập Google chưa
  static Future<bool> isSignedIn() async {
    try {
      return await _googleSignIn.isSignedIn();
    } catch (_) {
      return false;
    }
  }

  /// Lấy thông tin tài khoản hiện tại (nếu có)
  static GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;
}
