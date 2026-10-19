import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../models/cart_result.dart';
import '../models/ingredient.dart';
import '../provider/cart_provider.dart';
import '../services/deeplink_service.dart';

/// Screen 08_Shopping_List from Stitch Project "Food Decider Flutter UI"
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
  final Set<String> _checkedItemNames = {};

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

  void _toggleItem(String name) {
    setState(() {
      if (_checkedItemNames.contains(name)) {
        _checkedItemNames.remove(name);
      } else {
        _checkedItemNames.add(name);
      }
    });
  }

  void _clearChecked() {
    setState(() {
      _checkedItemNames.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Danh sách mua sắm'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, size: 22),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
      body: Consumer<CartProvider>(
        builder: (context, provider, child) {
          return switch (provider.status) {
            CartStatus.idle || CartStatus.loading => _buildLoadingState(),
            CartStatus.error => _buildErrorState(provider),
            CartStatus.success =>
              _buildSuccessState(provider.cart!, provider.isFromCache),
          };
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          CircularProgressIndicator(color: AppTheme.primary),
          SizedBox(height: 16),
          Text(
            'Đang tra cứu giá & cửa hàng tại Bách Hoá Xanh...',
            style: TextStyle(fontSize: 14, color: AppTheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(CartProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
            const SizedBox(height: 12),
            Text(
              provider.errorMessage ?? 'Không thể lập giỏ hàng',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.error, fontSize: 14),
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
    );
  }

  Widget _buildSuccessState(CartResult cart, bool isFromCache) {
    final allItems = cart.items;
    final totalCount = allItems.length;
    final doneCount = _checkedItemNames.length;
    final remainingCount = totalCount - doneCount;
    final progressPercent = totalCount > 0 ? (doneCount / totalCount * 100).toInt() : 0;

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Progress Card (Tiến độ đi chợ)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x12FF6B35),
                          blurRadius: 16,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryFixed,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.shopping_cart,
                                      color: AppTheme.primary, size: 20),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'TIẾN ĐỘ ĐI CHỢ',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.8,
                                        color: AppTheme.onSurfaceVariant,
                                      ),
                                    ),
                                    Text(
                                      'Đã chuẩn bị: $doneCount / $totalCount món ($progressPercent%)',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (doneCount > 0)
                              IconButton(
                                icon: const Icon(Icons.delete_sweep,
                                    color: AppTheme.onSurfaceVariant, size: 20),
                                onPressed: _clearChecked,
                                tooltip: 'Xóa các món đã chọn',
                              ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Progress Bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: totalCount > 0 ? (doneCount / totalCount) : 0,
                            backgroundColor: AppTheme.surfaceContainerHigh,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                AppTheme.primaryContainer),
                            minHeight: 8,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Còn $remainingCount món cần chuẩn bị',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              '$progressPercent%',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 2. Section: Cần mua hôm nay
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.local_mall, color: AppTheme.primary, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Cần mua hôm nay',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.onSurface,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryFixed,
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: Text(
                              '$remainingCount',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.onPrimaryFixed,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        'Sắp xếp theo quầy',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.secondaryMint,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // 3. Item Cards List
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: allItems.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = allItems[index];
                      final isChecked = _checkedItemNames.contains(item.name);

                      return InkWell(
                        onTap: () => _toggleItem(item.name),
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isChecked
                                ? AppTheme.surfaceContainerLow
                                : AppTheme.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x06000000),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Checkbox indicator
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: isChecked
                                      ? AppTheme.primary
                                      : AppTheme.surfaceContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: isChecked
                                    ? const Icon(Icons.check,
                                        size: 16, color: Colors.white)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              // Thumbnail placeholder
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceContainer,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.fastfood_outlined,
                                  size: 22,
                                  color: AppTheme.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Title and details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: isChecked
                                            ? AppTheme.onSurfaceVariant
                                            : AppTheme.onSurface,
                                        decoration: isChecked
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryFixed
                                                .withOpacity(0.4),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '${item.packQuantity} gói',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.primaryDark,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${_formatCurrency(item.totalPrice)} đ',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Bottom Checkout Bar
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x10000000),
                  blurRadius: 10,
                  offset: Offset(0, -3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tổng dự tính:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '${_formatCurrency(cart.totalEstimatedPrice)} đ',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    // ShopeeFood
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          DeeplinkService.openShopeeFood(widget.dishName);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEE4D2D), // Shopee Orange
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'ShopeeFood',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // GrabMart
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          DeeplinkService.openGrabMart(widget.dishName);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00B14F), // Grab Green
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'GrabMart',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
