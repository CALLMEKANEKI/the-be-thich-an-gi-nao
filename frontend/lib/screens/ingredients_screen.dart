import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../models/ingredient.dart';
import '../provider/ingredient_provider.dart';
import 'shopping_cart_screen.dart';

class IngredientsScreen extends StatefulWidget {
  final int dishId;
  final String dishName;

  const IngredientsScreen({
    super.key,
    required this.dishId,
    required this.dishName,
  });

  @override
  State<IngredientsScreen> createState() => _IngredientsScreenState();
}

class _IngredientsScreenState extends State<IngredientsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IngredientProvider>().fetchIngredients(widget.dishId);
    });
  }

  void _goToCart(List<Ingredient> ingredients) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShoppingCartScreen(
          dishId: widget.dishId,
          dishName: widget.dishName,
          ingredients: ingredients,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nguyên liệu: ${widget.dishName} 🍳'),
      ),
      body: Consumer<IngredientProvider>(
        builder: (context, provider, child) {
          return switch (provider.status) {
            IngredientStatus.idle || IngredientStatus.loading => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    CircularProgressIndicator(color: AppTheme.primaryColor),
                    SizedBox(height: 16),
                    Text(
                      'AI đang tính toán công thức nấu cho 2 người...',
                      style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            IngredientStatus.error => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text(
                        provider.errorMessage ?? 'Không thể tải nguyên liệu',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => provider.fetchIngredients(widget.dishId),
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              ),
            IngredientStatus.success => _buildIngredientsList(provider.ingredients),
          };
        },
      ),
    );
  }

  Widget _buildIngredientsList(List<Ingredient> ingredients) {
    if (ingredients.isEmpty) {
      return const Center(child: Text('Không tìm thấy danh sách nguyên liệu.'));
    }

    return Column(
      children: [
        // Ghi chú định lượng tham khảo
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            children: const [
              Icon(Icons.info_outline, color: Colors.deepOrange, size: 22),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Định lượng chuẩn cho 2 người ăn (tham khảo). Gia vị cơ bản (muối, mắm, tiêu...) đã được lược bỏ.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF8D3B00),
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Danh sách nguyên liệu
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: ingredients.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = ingredients[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    '${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity} ${item.unit}',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Nút chuyển sang Giỏ hàng
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => _goToCart(ingredients),
              icon: const Icon(Icons.shopping_cart_checkout),
              label: const Text(
                'Lên Giỏ Hàng Bách Hoá Xanh 🛒',
                style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
