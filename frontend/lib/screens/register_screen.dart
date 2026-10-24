import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../provider/auth_provider.dart';
import 'login_screen.dart';
import '../services/google_auth_service.dart';

/// Screen 10_Register from Stitch "Food Decider Flutter UI"
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeTerms = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _errorMessage;
  bool _passwordMismatch = false;

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validatePasswordMatch() {
    if (_confirmPasswordController.text.isNotEmpty &&
        _passwordController.text != _confirmPasswordController.text) {
      if (!_passwordMismatch) {
        setState(() {
          _passwordMismatch = true;
        });
      }
    } else {
      if (_passwordMismatch) {
        setState(() {
          _passwordMismatch = false;
        });
      }
    }
  }

  Future<void> _handleRegister() async {
    setState(() {
      _errorMessage = null;
    });

    final name = _nameController.text.trim();
    final contact = _contactController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty || contact.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng điền đầy đủ tất cả các trường!';
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        _errorMessage = 'Mật khẩu phải chứa ít nhất 6 ký tự!';
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _passwordMismatch = true;
        _errorMessage = 'Mật khẩu xác nhận không khớp. Vui lòng kiểm tra lại!';
      });
      return;
    }

    if (!_agreeTerms) {
      setState(() {
        _errorMessage = 'Vui lòng đồng ý với Điều khoản dịch vụ & Chính sách bảo mật!';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.register(
      name: name,
      contact: contact,
      password: password,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.celebration, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('Chào mừng $name gia nhập hội mê ăn ngon! 🎉'),
              ],
            ),
            backgroundColor: AppTheme.secondary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      Navigator.pop(context);
    } else {
      setState(() {
        _errorMessage = authProvider.lastError ?? 'Đăng ký thất bại. Vui lòng kiểm tra lại thông tin!';
      });
    }
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      setState(() {
        _isGoogleLoading = true;
        _errorMessage = null;
      });

      final account = await GoogleAuthService.signIn();

      if (account == null) {
        // Người dùng đã đóng/hủy hộp thoại chọn tài khoản Google
        if (mounted) {
          setState(() {
            _isGoogleLoading = false;
          });
        }
        return;
      }

      final email = account.email;
      final name = account.displayName ?? account.email.split('@').first;

      if (!mounted) return;
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.loginWithGoogle(email, name);

      if (!mounted) return;

      setState(() {
        _isGoogleLoading = false;
      });

      if (success) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Chào mừng ${authProvider.displayName}! Đăng ký qua Google thành công 🎉'),
                  ),
                ],
              ),
              backgroundColor: AppTheme.secondary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        Navigator.pop(context);
      } else {
        setState(() {
          _errorMessage = authProvider.lastError ?? 'Đăng nhập Google thất bại. Vui lòng thử lại!';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isGoogleLoading = false;
        _errorMessage = 'Không thể kết nối dịch vụ Google Sign-In ($e). Vui lòng kiểm tra tài khoản Google trên thiết bị!';
      });
    }
  }

  void _handleAppleSignIn() {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(
          content: Text('Tính năng Đăng nhập bằng Apple ID hiện chỉ khả dụng trên thiết bị iOS.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface.withValues(alpha: 0.9),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.onSurface),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Quay lại',
        ),
        title: const Text(
          'Đăng ký',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurface,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Warm Graphic / Avatar Card
              _buildHeaderCard(),

              const SizedBox(height: 16),

              // 2. Register Form Card
              _buildFormCard(),

              const SizedBox(height: 20),

              // 3. Social Divider
              _buildDivider(),

              const SizedBox(height: 16),

              // 4. Social Logins
              _buildSocialButtons(),

              const SizedBox(height: 20),

              // 5. Footer Link to Login
              _buildFooter(),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryFixed.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryFixedDim.withValues(alpha: 0.5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08FF6B35),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.restaurant, size: 14, color: AppTheme.primary),
                      SizedBox(width: 4),
                      Text(
                        'Thành viên mới',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tạo tài khoản mới',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.onSurface,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Chỉ 30 giây để bắt đầu hành trình ăn ngon!',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x10000000),
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.rice_bowl,
                  size: 38,
                  color: AppTheme.primaryContainer,
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppTheme.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0CFF6B35),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Field 1: Nickname
            _buildTextField(
              label: 'Tên đăng nhập',
              controller: _nameController,
              icon: Icons.sentiment_satisfied_alt,
            ),

            const SizedBox(height: 14),

            // Field 2: Email / Phone
            _buildTextField(
              label: 'Email hoặc Số điện thoại',
              controller: _contactController,
              icon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
            ),

            const SizedBox(height: 14),

            // Field 3: Password
            _buildPasswordField(
              label: 'Mật khẩu (Tối thiểu 6 ký tự)',
              controller: _passwordController,
              obscure: _obscurePassword,
              onToggleObscure: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
              onChanged: (_) => _validatePasswordMatch(),
            ),

            const SizedBox(height: 14),

            // Field 4: Confirm Password
            _buildPasswordField(
              label: 'Xác nhận mật khẩu',
              controller: _confirmPasswordController,
              obscure: _obscureConfirmPassword,
              isConfirm: true,
              hasError: _passwordMismatch,
              onToggleObscure: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
              onChanged: (_) => _validatePasswordMatch(),
            ),

            // Password mismatch helper
            if (_passwordMismatch) ...[
              const SizedBox(height: 6),
              Row(
                children: const [
                  Icon(Icons.error_outline, size: 15, color: Color(0xFFBA1A1A)),
                  SizedBox(width: 4),
                  Text(
                    'Mật khẩu xác nhận không khớp. Vui lòng kiểm tra lại!',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFBA1A1A),
                    ),
                  ),
                ],
              ),
            ],

            // General error banner
            if (_errorMessage != null && !_passwordMismatch) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFDAD6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF93000A),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 14),

            // Terms and Privacy Checkbox
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _agreeTerms,
                    activeColor: AppTheme.primaryContainer,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    onChanged: (val) {
                      setState(() {
                        _agreeTerms = val ?? false;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.onSurface,
                        height: 1.35,
                      ),
                      children: [
                        TextSpan(text: 'Tôi đồng ý với '),
                        TextSpan(
                          text: 'Điều khoản dịch vụ',
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(text: ' & '),
                        TextSpan(
                          text: 'Chính sách bảo mật',
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(text: ' của ứng dụng.'),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Submit Button
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryContainer,
                  foregroundColor: AppTheme.onPrimary,
                  elevation: 4,
                  shadowColor: const Color(0x59FF6B35),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            'ĐĂNG KÝ',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, size: 18),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    String? sublabel,
    required TextEditingController controller,
    String hint = '',
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurface,
              ),
            ),
            if (sublabel != null) ...[
              const SizedBox(width: 4),
              Text(
                sublabel,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 14, color: AppTheme.onSurface),
            decoration: InputDecoration(
              hintText: hint.isNotEmpty ? hint : null,
              hintStyle: const TextStyle(fontSize: 13, color: AppTheme.outline),
              prefixIcon: Icon(icon, size: 20, color: AppTheme.onSurfaceVariant),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    String hint = '',
    required bool obscure,
    required VoidCallback onToggleObscure,
    ValueChanged<String>? onChanged,
    bool isConfirm = false,
    bool hasError = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: hasError
                ? const Color(0xFFFFDAD6).withValues(alpha: 0.5)
                : AppTheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: hasError
                ? Border.all(color: const Color(0xFFBA1A1A).withValues(alpha: 0.6), width: 1.5)
                : null,
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            onChanged: onChanged,
            style: TextStyle(
              fontSize: 14,
              color: hasError ? const Color(0xFFBA1A1A) : AppTheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: hint.isNotEmpty ? hint : null,
              hintStyle: const TextStyle(fontSize: 13, color: AppTheme.outline),
              prefixIcon: Icon(
                isConfirm ? Icons.lock_reset : Icons.lock_outline,
                size: 20,
                color: hasError ? const Color(0xFFBA1A1A) : AppTheme.onSurfaceVariant,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_off : Icons.visibility,
                  size: 20,
                  color: hasError ? const Color(0xFFBA1A1A) : AppTheme.onSurfaceVariant,
                ),
                onPressed: onToggleObscure,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Row(
      children: const [
        Expanded(child: Divider(color: AppTheme.surfaceContainerHigh, thickness: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'HOẶC TIẾP TỤC VỚI',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(child: Divider(color: AppTheme.surfaceContainerHigh, thickness: 1)),
      ],
    );
  }

  Widget _buildSocialButtons() {
    return Row(
      children: [
        // Google Button
        Expanded(
          child: OutlinedButton(
            onPressed: (_isLoading || _isGoogleLoading) ? null : _handleGoogleSignIn,
            style: OutlinedButton.styleFrom(
              backgroundColor: AppTheme.surfaceContainerLowest,
              foregroundColor: AppTheme.onSurface,
              side: const BorderSide(color: Color(0x1A000000)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isGoogleLoading
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEA4335)),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Đang xử lý...',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEA4335),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'G',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Google',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(width: 12),
        // Apple Button
        Expanded(
          child: OutlinedButton(
            onPressed: _handleAppleSignIn,
            style: OutlinedButton.styleFrom(
              backgroundColor: AppTheme.surfaceContainerLowest,
              foregroundColor: AppTheme.onSurface,
              side: const BorderSide(color: Color(0x1A000000)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.apple, size: 22, color: AppTheme.onSurface),
                SizedBox(width: 6),
                Text(
                  'Apple',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Đã có tài khoản? ',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'Đăng nhập',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
                SizedBox(width: 2),
                Icon(Icons.chevron_right, size: 16, color: AppTheme.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
