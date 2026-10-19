import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../models/ingredient.dart';
import '../provider/ingredient_provider.dart';
import 'shopping_cart_screen.dart';

/// Screen 07_Ingredients from Stitch Project "Food Decider Flutter UI"
class IngredientsScreen extends StatefulWidget {
  final int? dishId;
  final String dishName;

  const IngredientsScreen({
    super.key,
    this.dishId,
    required this.dishName,
  });

  @override
  State<IngredientsScreen> createState() => _IngredientsScreenState();
}

class _IngredientsScreenState extends State<IngredientsScreen> {
  final Set<int> _selectedIngredientIds = {};
  bool _isAllSelected = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final id = widget.dishId ?? 1;
      context.read<IngredientProvider>().fetchIngredients(id).then((_) {
        final ingredients = context.read<IngredientProvider>().ingredients;
        if (mounted) {
          setState(() {
            _selectedIngredientIds.addAll(ingredients.map((e) => e.id));
            _isAllSelected = true;
          });
        }
      });
    });
  }

  void _toggleAll(List<Ingredient> ingredients) {
    setState(() {
      if (_isAllSelected) {
        _selectedIngredientIds.clear();
        _isAllSelected = false;
      } else {
        _selectedIngredientIds.addAll(ingredients.map((e) => e.id));
        _isAllSelected = true;
      }
    });
  }

  void _goToCart(List<Ingredient> ingredients) {
    final selectedItems =
        ingredients.where((i) => _selectedIngredientIds.contains(i.id)).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShoppingCartScreen(
          dishId: widget.dishId ?? 1,
          dishName: widget.dishName,
          ingredients: selectedItems.isNotEmpty ? selectedItems : ingredients,
        ),
      ),
    );
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
        title: const Text('Chi tiết món ăn'),
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
      body: Consumer<IngredientProvider>(
        builder: (context, provider, child) {
          return switch (provider.status) {
            IngredientStatus.idle || IngredientStatus.loading => _buildLoadingState(),
            IngredientStatus.error => _buildErrorState(provider),
            IngredientStatus.success => _buildSuccessState(provider.ingredients),
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
            'Đang tính toán công thức và nguyên liệu cho bé...',
            style: TextStyle(fontSize: 14, color: AppTheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(IngredientProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
            const SizedBox(height: 12),
            Text(
              provider.errorMessage ?? 'Không thể tải nguyên liệu',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.error, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context
                  .read<IngredientProvider>()
                  .fetchIngredients(widget.dishId ?? 1),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessState(List<Ingredient> ingredients) {
    final selectedCount = _selectedIngredientIds.length;

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Dish Banner Card
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x10FF6B35),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryFixed,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.restaurant_menu,
                                color: AppTheme.primary,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'CÔNG THỨC CHUẨN VỊ',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.dishName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Metadata pills
                        Row(
                          children: [
                            _buildInfoChip(Icons.timer_outlined, '30 phút'),
                            const SizedBox(width: 8),
                            _buildInfoChip(Icons.people_outline, '2-4 phần ăn'),
                            const SizedBox(width: 8),
                            _buildInfoChip(Icons.local_fire_department, 'Dễ làm'),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Ingredients Header Row with Select All
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.shopping_basket,
                              color: AppTheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Nguyên liệu (${ingredients.length})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () => _toggleAll(ingredients),
                        child: Text(
                          _isAllSelected ? 'Bỏ chọn tất cả' : 'Chọn tất cả',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.secondaryMint,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Ingredients List
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: ingredients.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = ingredients[index];
                      final isSelected = _selectedIngredientIds.contains(item.id);

                      return InkWell(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedIngredientIds.remove(item.id);
                              _isAllSelected = false;
                            } else {
                              _selectedIngredientIds.add(item.id);
                              if (_selectedIngredientIds.length ==
                                  ingredients.length) {
                                _isAllSelected = true;
                              }
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primaryContainer.withOpacity(0.5)
                                  : Colors.transparent,
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
                            children: [
                              // Checkbox
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.primaryContainer
                                      : AppTheme.surfaceContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check,
                                        size: 16, color: Colors.white)
                                    : null,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  item.name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? AppTheme.onSurface
                                        : AppTheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryFixed.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${item.amount} ${item.unit}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primaryDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Bottom CTA: TẠO GIỎ HÀNG
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
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
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: selectedCount == 0 ? null : () => _goToCart(ingredients),
                icon: const Icon(Icons.shopping_cart_checkout, size: 20),
                label: Text(
                  'TẠO GIỎ HÀNG ($selectedCount MÓN)',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryContainer,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: const Color(0x4DFF6B35),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.primary),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
