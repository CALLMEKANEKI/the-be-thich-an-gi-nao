import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../models/cart_result.dart';
import '../models/ingredient.dart';
import '../provider/cart_provider.dart';
import '../services/deeplink_service.dart';

/// Screen 08_Shopping_List matching Notion System Architecture & Handoff Guide
/// Segregated into:
/// 1. "Có thể mua ở Bách Hoá Xanh" (available = true, with direct buy search_url button)
/// 2. "Mua tại chợ (Tự mua)" (available = false, shows note, no buy button)
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

  String _formatQuantity(double q) {
    if (q == q.roundToDouble()) {
      return q.toInt().toString();
    }
    return q.toString();
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
        title: Column(
          children: [
            const Text(
              'Danh sách mua sắm',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            Text(
              widget.dishName,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 22),
            tooltip: 'Tải lại giỏ hàng',
            onPressed: () {
              context.read<CartProvider>().createCart(
                    dishId: widget.dishId,
                    dishName: widget.dishName,
                    ingredients: widget.ingredients,
                  );
            },
          ),
          const SizedBox(width: 8),
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
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(color: AppTheme.primary),
            SizedBox(height: 18),
            Text(
              'Đang đối soát danh mục Bách Hoá Xanh...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurface,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Phân loại nguyên liệu siêu thị & chợ truyền thống',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant),
            ),
          ],
        ),
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
    final availableItems = cart.availableItems;
    final unavailableItems = cart.unavailableItems;
    final totalCount = cart.items.length;
    final doneCount = _checkedItemNames.length;
    final progressPercent =
        totalCount > 0 ? (doneCount / totalCount * 100).toInt() : 0;

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Offline Cache Banner (Notion requirement)
                  if (isFromCache)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFFFFECB3), width: 1),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.cloud_off,
                              size: 18, color: Color(0xFFB78103)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Dữ liệu cũ (offline) — lưu từ phiên trước',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF7A5800),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // 1. Progress & Summary Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x10FF6B35),
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
                                  child: const Icon(
                                    Icons.checklist_rtl_rounded,
                                    color: AppTheme.primary,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'TIẾN ĐỘ ĐI CHỢ',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.8,
                                        color: AppTheme.onSurfaceVariant,
                                      ),
                                    ),
                                    Text(
                                      'Đã xong: $doneCount / $totalCount món ($progressPercent%)',
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
                              TextButton.icon(
                                onPressed: _clearChecked,
                                icon: const Icon(Icons.restart_alt, size: 16),
                                label: const Text('Bỏ chọn'),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.onSurfaceVariant,
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Progress Bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value:
                                totalCount > 0 ? (doneCount / totalCount) : 0,
                            backgroundColor: AppTheme.surfaceContainerHigh,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                AppTheme.primaryContainer),
                            minHeight: 8,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Summary Statistics Pill Row
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.storefront,
                                        color: Color(0xFF2E7D32), size: 16),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Bách Hoá Xanh: ${cart.summary.available}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1B5E20),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF3E0),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.store,
                                        color: Color(0xFFE65100), size: 16),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Mua tại chợ: ${cart.summary.unavailable}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFFBF360C),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ==========================================
                  // 2. PHẦN 1: CÓ THỂ MUA Ở BÁCH HOÁ XANH
                  // ==========================================
                  _buildSectionHeader(
                    title: 'Có thể mua ở Bách Hoá Xanh',
                    count: availableItems.length,
                    icon: Icons.storefront_rounded,
                    accentColor: const Color(0xFF008848), // BHX Green
                    badgeBg: const Color(0xFFE8F5E9),
                    badgeFg: const Color(0xFF1B5E20),
                    description: 'Nguyên liệu khớp mã sản phẩm Bách Hoá Xanh',
                  ),

                  const SizedBox(height: 10),

                  if (availableItems.isEmpty)
                    _buildEmptySectionMessage(
                      message:
                          'Chưa tìm thấy sản phẩm nào trên Bách Hoá Xanh cho món này.',
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: availableItems.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        return _buildAvailableItemCard(availableItems[index]);
                      },
                    ),

                  const SizedBox(height: 24),

                  // ==========================================
                  // 3. PHẦN 2: MUA TẠI CHỢ (TỰ MUA)
                  // ==========================================
                  _buildSectionHeader(
                    title: 'Mua tại chợ (Tự mua)',
                    count: unavailableItems.length,
                    icon: Icons.shopping_basket_rounded,
                    accentColor: const Color(0xFFE65100), // Market Warm Orange
                    badgeBg: const Color(0xFFFFF3E0),
                    badgeFg: const Color(0xFFBF360C),
                    description:
                        'Nguyên liệu tươi/đặc sản không có trên siêu thị, tự mua tại chợ',
                  ),

                  const SizedBox(height: 10),

                  if (unavailableItems.isEmpty)
                    _buildEmptySectionMessage(
                      message:
                          'Tuyệt vời! Toàn bộ nguyên liệu đều có sẵn trên Bách Hoá Xanh.',
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: unavailableItems.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        return _buildUnavailableItemCard(
                            unavailableItems[index]);
                      },
                    ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // ==========================================
          // 4. BOTTOM CHECKOUT BAR (ĐÃ GỠ SHOPEE & GRAB)
          // ==========================================
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x12000000),
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Tổng tiền BHX dự tính:',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.onSurfaceVariant,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Chỉ tính mục Có thể mua trên Bách Hoá Xanh',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_formatCurrency(cart.totalEstimatedPrice)} đ',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      DeeplinkService.openUrl('https://www.bachhoaxanh.com');
                    },
                    icon: const Icon(Icons.storefront, size: 20),
                    label: const Text(
                      'Mở trang chủ Bách Hoá Xanh',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF008848), // BHX Brand Green
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
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

  Widget _buildSectionHeader({
    required String title,
    required int count,
    required IconData icon,
    required Color accentColor,
    required Color badgeBg,
    required Color badgeFg,
    required String description,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: accentColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: badgeFg,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 2),
        Padding(
          padding: const EdgeInsets.only(left: 28),
          child: Text(
            description,
            style: const TextStyle(
              fontSize: 11.5,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptySectionMessage({required String message}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 12.5,
          color: AppTheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildAvailableItemCard(CartItem item) {
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
          border: Border.all(
            color: isChecked
                ? Colors.transparent
                : const Color(0xFFC8E6C9), // Light green border
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Checkbox indicator
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isChecked
                    ? const Color(0xFF008848)
                    : AppTheme.surfaceContainer,
                borderRadius: BorderRadius.circular(6),
                border: isChecked
                    ? null
                    : Border.all(color: const Color(0xFFBDBDBD), width: 1.2),
              ),
              child: isChecked
                  ? const Icon(Icons.check, size: 15, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 10),

            // Thumbnail / Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 20,
                color: Color(0xFF008848),
              ),
            ),
            const SizedBox(width: 10),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName ?? item.ingredient,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: isChecked
                          ? AppTheme.onSurfaceVariant
                          : AppTheme.onSurface,
                      decoration:
                          isChecked ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Nguyên liệu: ${item.ingredient} (${_formatQuantity(item.quantity)} ${item.unit})',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${item.packsNeeded ?? 1} gói',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                      ),
                      if ((item.packsNeeded ?? 1) > 1 &&
                          item.priceVnd != null &&
                          item.priceVnd! > 0)
                        Text(
                          '${_formatCurrency(item.priceVnd!)} đ/gói',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                      Text(
                        '${_formatCurrency(item.totalPrice)} đ',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF008848),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Nút "Mua" mở search_url theo chuẩn Notion
            if (item.searchUrl != null && item.searchUrl!.isNotEmpty) ...[
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {
                  DeeplinkService.openUrl(item.searchUrl);
                },
                icon: const Icon(Icons.open_in_new, size: 12),
                label: const Text('Mua'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF008848), // BHX Green
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUnavailableItemCard(CartItem item) {
    final isChecked = _checkedItemNames.contains(item.ingredient);

    return InkWell(
      onTap: () => _toggleItem(item.ingredient),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isChecked
              ? AppTheme.surfaceContainerLow
              : AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isChecked
                ? Colors.transparent
                : const Color(0xFFFFE0B2), // Light amber border
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Checkbox indicator
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isChecked
                    ? const Color(0xFFE65100)
                    : AppTheme.surfaceContainer,
                borderRadius: BorderRadius.circular(6),
                border: isChecked
                    ? null
                    : Border.all(color: const Color(0xFFBDBDBD), width: 1.2),
              ),
              child: isChecked
                  ? const Icon(Icons.check, size: 15, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 10),

            // Thumbnail / Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.store,
                size: 20,
                color: Color(0xFFE65100),
              ),
            ),
            const SizedBox(width: 10),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.ingredient,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: isChecked
                                ? AppTheme.onSurfaceVariant
                                : AppTheme.onSurface,
                            decoration:
                                isChecked ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${_formatQuantity(item.quantity)} ${item.unit}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFE65100),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.info_outline,
                          size: 13, color: Color(0xFFD78800)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.note ??
                              'Chưa tìm thấy trên Bách Hoá Xanh (mua tại chợ)',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF865300),
                            fontStyle: FontStyle.italic,
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
      ),
    );
  }
}
