import 'package:flutter/material.dart';

class GoogleAccountPickerSheet extends StatefulWidget {
  const GoogleAccountPickerSheet({super.key});

  @override
  State<GoogleAccountPickerSheet> createState() => _GoogleAccountPickerSheetState();
}

class _GoogleAccountPickerSheetState extends State<GoogleAccountPickerSheet> {
  bool _showCustomInput = false;
  final TextEditingController _customNameController = TextEditingController();
  final TextEditingController _customEmailController = TextEditingController();
  String? _customError;

  @override
  void dispose() {
    _customNameController.dispose();
    _customEmailController.dispose();
    super.dispose();
  }

  void _selectAccount(String email, String name) {
    Navigator.of(context).pop({'email': email, 'name': name});
  }

  void _submitCustomAccount() {
    final email = _customEmailController.text.trim();
    final name = _customNameController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _customError = 'Vui lòng nhập địa chỉ email hợp lệ!';
      });
      return;
    }

    _selectAccount(email, name.isNotEmpty ? name : email.split('@').first);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header: Google Brand & Title
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFFEA4335),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text(
                  'G',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Đăng nhập bằng Google',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F1F1F),
                      ),
                    ),
                    Text(
                      'để tiếp tục đến Thế Bé Thích Ăn Gì?',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF5F6368),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20, color: Color(0xFF5F6368)),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Đóng',
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE0E0E0)),
          const SizedBox(height: 12),

          // Account 1: Bé Cưng Foodie
          _buildAccountTile(
            name: 'Bé Cưng Foodie',
            email: 'be.cung.foodie@gmail.com',
            avatarColor: const Color(0xFFFF6B35),
            avatarText: 'B',
            badgeIcon: Icons.restaurant,
            onTap: () => _selectAccount('be.cung.foodie@gmail.com', 'Bé Cưng Foodie'),
          ),

          const SizedBox(height: 6),

          // Account 2: Bé Yêu Ẩm Thực
          _buildAccountTile(
            name: 'Bé Yêu Ẩm Thực',
            email: 'be.yeu.amthuc@gmail.com',
            avatarColor: const Color(0xFF2E7D32),
            avatarText: 'Y',
            badgeIcon: Icons.favorite,
            onTap: () => _selectAccount('be.yeu.amthuc@gmail.com', 'Bé Yêu Ẩm Thực'),
          ),

          const SizedBox(height: 6),

          // Account 3: Sử dụng tài khoản khác
          if (!_showCustomInput)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F3F4),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFDADCE0)),
                ),
                child: const Icon(Icons.person_add_alt_1, color: Color(0xFF5F6368), size: 20),
              ),
              title: const Text(
                'Sử dụng một tài khoản khác',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F1F1F),
                ),
              ),
              subtitle: const Text(
                'Nhập email Google của bạn',
                style: TextStyle(fontSize: 12, color: Color(0xFF5F6368)),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF5F6368)),
              onTap: () {
                setState(() {
                  _showCustomInput = true;
                });
              },
            )
          else ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFDADCE0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Nhập thông tin tài khoản Google của bạn:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3C4043),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _customNameController,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Tên hiển thị',
                      labelStyle: const TextStyle(fontSize: 12),
                      hintText: 'VD: Bé Minh Nhật',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFDADCE0)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _customEmailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Email Google',
                      labelStyle: const TextStyle(fontSize: 12),
                      hintText: 'VD: minhnhat@gmail.com',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFDADCE0)),
                      ),
                    ),
                  ),
                  if (_customError != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _customError!,
                      style: const TextStyle(fontSize: 11, color: Color(0xFFD93025)),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _showCustomInput = false;
                            _customError = null;
                          });
                        },
                        child: const Text('Hủy', style: TextStyle(color: Color(0xFF5F6368))),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _submitCustomAccount,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A73E8),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Tiếp tục', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFE0E0E0)),
          const SizedBox(height: 10),

          // Privacy note
          const Text(
            'Để tiếp tục, Google sẽ chia sẻ tên và địa chỉ email của bạn với Thế Bé Thích Ăn Gì? theo Chính sách quyền riêng tư.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              height: 1.35,
              color: Color(0xFF5F6368),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountTile({
    required String name,
    required String email,
    required Color avatarColor,
    required String avatarText,
    required IconData badgeIcon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF1F3F4)),
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: avatarColor,
                  child: Text(
                    avatarText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x20000000),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Icon(badgeIcon, size: 10, color: avatarColor),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F1F1F),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF5F6368),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 13, color: Color(0xFF5F6368)),
          ],
        ),
      ),
    );
  }
}
