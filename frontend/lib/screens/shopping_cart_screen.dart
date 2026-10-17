import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../models/cart_result.dart';
import '../models/ingredient.dart';
import '../provider/cart_provider.dart';
import '../services/deeplink_service.dart';

class ShoppingCartScreen extends StatefulWidget {
  final int dishId;
  final String dishName;
  final List<Ingredient> ingredients;

  const ShoppingCartScreen({
    super.key,
    required this.dishId,
    required this.dishName,
    required this.ingredients,
  });

  @override
  State<ShoppingCartScreen> createState() => _ShoppingCartScreenState();
}

class _ShoppingCartScreenState extends State<ShoppingCartScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartProvider>().createCart(
            dishId: widget.dishId,
            dishName: widget.dishName,
            ingredients: widget.ingredients,
          );
    });
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Giỏ Hàng: ${widget.dishName} 🛒'),
      ),
      body: Consumer<CartProvider>(
        builder: (context, provider, child) {
          return switch (provider.status) {
            CartStatus.idle || CartStatus.loading => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    CircularProgressIndicator(color: AppTheme.primaryColor),
                    SizedBox(height: 16),
                    Text(
                      'Đang tra cứu giá & số gói tại Bách Hoá Xanh...',
                      style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            CartStatus.error => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text(
                        provider.errorMessage ?? 'Không thể lập giỏ hàng',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          provider.createCart(
                            dishId: widget.dishId,
                            dishName: widget.dishName,
                            ingredients: widget.ingredients,
                          );
                        },
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              ),
            CartStatus.success => _buildCartContent(provider.cart!, provider.isFromCache),
          };
        },
      ),
    );
  }

  Widget _buildCartContent(CartResult cart, bool isFromCache) {
    final available = cart.availableItems;
    final unavailable = cart.unavailableItems;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Offline nếu dùng cache SQLite
          if (isFromCache)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                children: const [
                  Icon(Icons.wifi_off, color: Colors.deepOrange, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Dữ liệu cũ (offline)',
                    style: TextStyle(
                      color: Colors.deepOrange,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

          // Card Tổng kết chi phí (Summary)
          Card(
            color: Colors.green.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.green.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tổng tiền ước tính:',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        '${_formatCurrency(cart.summary.estimatedTotalVnd)} đ',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle, size: 16, color: Colors.green),
                          const SizedBox(width: 6),
                          Text(
                            'Có thể mua: ${cart.summary.available} món',
                            style: const TextStyle(fontSize: 13, color: Colors.green),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.help_outline, size: 16, color: Colors.orange),
                          const SizedBox(width: 6),
                          Text(
                            'Tự mua: ${cart.summary.unavailable} món',
                            style: const TextStyle(fontSize: 13, color: Colors.orange),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (cart.notionPageId != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.cloud_done, size: 15, color: Colors.blue),
                          SizedBox(width: 6),
                          Text(
                            'Đã tự động lưu vào Notion Shopping List ✅',
                            style: TextStyle(fontSize: 11.5, color: Colors.blue, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // MỤC 1: CÓ THỂ MUA TẠI BÁCH HOÁ XANH
          if (available.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.shopping_bag, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(
                  'CÓ THỂ MUA TẠI BÁCH HOÁ XANH (${available.length})',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...available.map((item) => _buildAvailableItem(item)),
            const SizedBox(height: 20),
          ],

          // MỤC 2: TỰ MUA (Chưa tìm thấy trên Bách Hoá Xanh)
          if (unavailable.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.store, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Text(
                  'TỰ MUA NGOÀI CHỢ (${unavailable.length})',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...unavailable.map((item) => _buildUnavailableItem(item)),
          ],
        ],
      ),
    );
  }

  Widget _buildAvailableItem(CartItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.ingredient,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                Text(
                  'Cần ${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity} ${item.unit}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName ?? '',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item.packsNeeded ?? 1} gói × ${_formatCurrency(item.priceVnd ?? 0)}đ = ${_formatCurrency(item.subtotalVnd ?? 0)}đ',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF2E7D32),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (item.searchUrl != null && item.searchUrl!.isNotEmpty)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        DeeplinkService.openUrl(item.searchUrl);
                      },
                      child: const Text(
                        'Mua ngay',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnavailableItem(CartItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.ingredient,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.note ?? 'Chưa tìm thấy trên Bách Hoá Xanh',
                  style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity} ${item.unit}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
