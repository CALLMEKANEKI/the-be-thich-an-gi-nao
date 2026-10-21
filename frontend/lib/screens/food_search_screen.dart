import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../models/dish_recommendation.dart';
import '../provider/auth_provider.dart';
import '../provider/dish_search_provider.dart';
import '../services/location_service.dart';
import 'ingredients_screen.dart';
import 'login_screen.dart';
import 'spin_wheel_screen.dart';

/// Screen 11_Food_Search from Stitch Project "Food Decider Flutter UI"
class FoodSearchScreen extends StatefulWidget {
  final String? initialQuery;

  const FoodSearchScreen({super.key, this.initialQuery});

  @override
  State<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends State<FoodSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<DishSearchProvider>().search(widget.initialQuery!);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchSubmitted(String val) {
    if (val.trim().isNotEmpty) {
      context.read<DishSearchProvider>().search(val);
    }
  }

  void _setQueryAndSearch(String query) {
    _searchController.text = query;
    context.read<DishSearchProvider>().search(query);
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
        title: const Text('Tìm kiếm món ăn'),
        actions: [
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: InkWell(
                  onTap: () {
                    if (!auth.isLoggedIn) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(9999),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: auth.isLoggedIn
                          ? Text(
                              auth.displayName.isNotEmpty
                                  ? auth.displayName[0].toUpperCase()
                                  : 'B',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            )
                          : const Icon(Icons.person, color: Colors.white, size: 18),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Input Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: _buildSearchBar(),
            ),

            // Content Area based on Provider State
            Expanded(
              child: Consumer<DishSearchProvider>(
                builder: (context, provider, _) {
                  if (provider.status == DishSearchStatus.loading) {
                    return _buildLoadingState();
                  }

                  if (provider.status == DishSearchStatus.error) {
                    return _buildErrorState(provider);
                  }

                  if (provider.hasActiveSearch) {
                    if (provider.dishes.isEmpty) {
                      return _buildEmptyState(provider);
                    }
                    return _buildResultsState(provider);
                  }

                  return _buildDefaultState(provider);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // SEARCH BAR WIDGET
  // ==========================================
  Widget _buildSearchBar() {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10FF6B35),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          const Icon(
            Icons.search,
            color: AppTheme.primary,
            size: 24,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              textInputAction: TextInputAction.search,
              onSubmitted: _onSearchSubmitted,
              decoration: const InputDecoration(
                hintText: 'Hôm nay bé thèm món gì?',
                hintStyle: TextStyle(
                  fontSize: 14.5,
                  color: AppTheme.onSurfaceVariant,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurface,
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            InkWell(
              onTap: () {
                _searchController.clear();
                context.read<DishSearchProvider>().clearSearch();
              },
              borderRadius: BorderRadius.circular(9999),
              child: Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: AppTheme.surfaceContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ==========================================
  // STATE 1: DEFAULT STATE (CHƯA NHẬP TỪ KHÓA)
  // ==========================================
  Widget _buildDefaultState(DishSearchProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Tìm kiếm gần đây
          if (provider.recentSearches.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
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
                        children: const [
                          Icon(Icons.history, color: AppTheme.primary, size: 20),
                          SizedBox(width: 6),
                          Text(
                            'Tìm kiếm gần đây',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () => provider.clearRecentSearches(),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Xoá tất cả',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: provider.recentSearches.map((item) {
                      return InkWell(
                        onTap: () => _setQueryAndSearch(item),
                        borderRadius: BorderRadius.circular(9999),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryFixed.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                item,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.onPrimaryFixed,
                                ),
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () => provider.removeRecentSearch(item),
                                child: const Icon(
                                  Icons.close,
                                  size: 14,
                                  color: AppTheme.onPrimaryFixed,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 2. Món đang thịnh hành 🔥
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
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
                      children: const [
                        Icon(Icons.local_fire_department, color: AppTheme.primary, size: 20),
                        SizedBox(width: 6),
                        Text(
                          'Món đang thịnh hành',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryFixed,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: const Text(
                        'HOT',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.onPrimaryFixedVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildTrendingChip('🥢', 'Bún đậu'),
                    _buildTrendingChip('🍛', 'Cơm tấm'),
                    _buildTrendingChip('🌶️', 'Mì cay 7 cấp'),
                    _buildTrendingChip('🧋', 'Trà sữa trân châu'),
                    _buildTrendingChip('🍜', 'Phở bò tái lăn'),
                    _buildTrendingChip('🥗', 'Gỏi cuốn'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 3. Gợi ý theo nhóm vị
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.restaurant_menu, color: AppTheme.secondary, size: 20),
                    SizedBox(width: 6),
                    Text(
                      'Gợi ý theo nhóm vị',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.3,
                  children: [
                    _buildTasteCard(
                      icon: Icons.spa,
                      title: 'Thanh đạm',
                      subtitle: 'Canh, rau, hấp',
                      bg: AppTheme.secondaryFixed.withValues(alpha: 0.35),
                      iconBg: AppTheme.secondaryFixed,
                      iconFg: AppTheme.secondary,
                      onTap: () => _setQueryAndSearch('Thanh đạm'),
                    ),
                    _buildTasteCard(
                      icon: Icons.dinner_dining,
                      title: 'Đậm đà',
                      subtitle: 'Kho, nướng, xào',
                      bg: AppTheme.primaryFixed.withValues(alpha: 0.35),
                      iconBg: AppTheme.primaryFixed,
                      iconFg: AppTheme.primary,
                      onTap: () => _setQueryAndSearch('Đậm đà'),
                    ),
                    _buildTasteCard(
                      icon: Icons.soup_kitchen,
                      title: 'Nóng hổi',
                      subtitle: 'Lẩu, mì nước',
                      bg: AppTheme.tertiaryFixed.withValues(alpha: 0.35),
                      iconBg: AppTheme.tertiaryFixed,
                      iconFg: AppTheme.tertiary,
                      onTap: () => _setQueryAndSearch('Nóng hổi'),
                    ),
                    _buildTasteCard(
                      icon: Icons.icecream,
                      title: 'Mát lạnh',
                      subtitle: 'Chè, kem, sinh tố',
                      bg: AppTheme.surfaceContainerHigh,
                      iconBg: AppTheme.surfaceContainerHighest,
                      iconFg: AppTheme.secondary,
                      onTap: () => _setQueryAndSearch('Mát lạnh'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTrendingChip(String emoji, String text) {
    return InkWell(
      onTap: () => _setQueryAndSearch(text),
      borderRadius: BorderRadius.circular(9999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(9999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 5),
            Text(
              text,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTasteCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color bg,
    required Color iconBg,
    required Color iconFg,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: iconFg),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppTheme.onSurfaceVariant,
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

  // ==========================================
  // STATE 2: RESULTS STATE (CÓ KẾT QUẢ TÌM KIẾM)
  // ==========================================
  Widget _buildResultsState(DishSearchProvider provider) {
    return Column(
      children: [
        // Category Pills (if any)
        if (provider.categories.isNotEmpty)
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: provider.categories.length + 1,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                if (index == 0) {
                  final isSelected = provider.selectedCategory == null;
                  return ChoiceChip(
                    label: const Text('Tất cả'),
                    selected: isSelected,
                    onSelected: (_) => provider.selectCategory(null),
                    selectedColor: AppTheme.primaryFixed,
                    backgroundColor: AppTheme.surfaceContainerLowest,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppTheme.onPrimaryFixed : AppTheme.onSurfaceVariant,
                    ),
                  );
                }
                final cat = provider.categories[index - 1];
                final isSelected = provider.selectedCategory == cat.name;
                return ChoiceChip(
                  label: Text('${cat.name} (${cat.count})'),
                  selected: isSelected,
                  onSelected: (_) => provider.selectCategory(cat.name),
                  selectedColor: AppTheme.primaryFixed,
                  backgroundColor: AppTheme.surfaceContainerLowest,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AppTheme.onPrimaryFixed : AppTheme.onSurfaceVariant,
                  ),
                );
              },
            ),
          ),

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: RichText(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.onSurfaceVariant,
                    ),
                    children: [
                      const TextSpan(text: 'Tìm thấy '),
                      TextSpan(
                        text: '${provider.total} món',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                      if (provider.query.isNotEmpty) ...[
                        const TextSpan(text: ' với \''),
                        TextSpan(
                          text: provider.query,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                        const TextSpan(text: '\''),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // List of Dishes
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            itemCount: provider.dishes.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final dish = provider.dishes[index];
              return _buildDishCard(dish);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDishCard(DishRecommendation dish) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => IngredientsScreen(dishName: dish.name),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Thumbnail image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 80,
                    height: 80,
                    color: AppTheme.surfaceContainer,
                    child: dish.imageUrl.isNotEmpty
                        ? Image.network(
                            dish.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.ramen_dining,
                              size: 36,
                              color: AppTheme.primary,
                            ),
                          )
                        : const Icon(
                            Icons.ramen_dining,
                            size: 36,
                            color: AppTheme.primary,
                          ),
                  ),
                ),
                Positioned(
                  top: 4,
                  left: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.star, size: 10, color: Color(0xFFFFB300)),
                        SizedBox(width: 2),
                        Text(
                          '4.8',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dish.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 13, color: AppTheme.primary),
                      const SizedBox(width: 4),
                      const Text(
                        '20-30 phút',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text('•', style: TextStyle(color: AppTheme.onSurfaceVariant)),
                      const SizedBox(width: 6),
                      Text(
                        dish.category.isNotEmpty ? dish.category : 'Bổ dưỡng',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryFixed.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          dish.category.isNotEmpty ? dish.category : 'Món ngon',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.secondary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryFixed.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Chuẩn vị',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chevron_right,
                size: 20,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // STATE 3: EMPTY STATE (KHÔNG TÌM THẤY KẾT QUẢ)
  // ==========================================
  Widget _buildEmptyState(DishSearchProvider provider) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0C000000),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Character Illustration
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppTheme.primaryFixed.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.search_off,
                    size: 46,
                    color: AppTheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Chưa tìm thấy món này rồi...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Bé thử tìm với từ khóa khác hoặc để Vòng quay may mắn quyết định giúp nhé!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // Button to Spin Wheel
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SpinWheelScreen(
                          latitude: LocationService.defaultLatitude,
                          longitude: LocationService.defaultLongitude,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.casino, size: 20),
                  label: const Text('THỬ VÒNG QUAY NGAY'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryContainer,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Quick Suggestions
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'Gợi ý:',
                    style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
                  ),
                  _buildSuggestText('Bún'),
                  const Text('•', style: TextStyle(color: AppTheme.onSurfaceVariant)),
                  _buildSuggestText('Phở'),
                  const Text('•', style: TextStyle(color: AppTheme.onSurfaceVariant)),
                  _buildSuggestText('Cơm'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestText(String text) {
    return InkWell(
      onTap: () => _setQueryAndSearch(text),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: AppTheme.primary,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  // ==========================================
  // STATE 4: LOADING STATE
  // ==========================================
  Widget _buildLoadingState() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        // Pulsing banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.primaryFixed.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: const [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Đang tìm món ngon cho bé...',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onPrimaryFixed,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Skeleton Cards
        for (int i = 0; i < 3; i++) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 140,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 90,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            width: 50,
                            height: 16,
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 60,
                            height: 16,
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceContainer,
                              borderRadius: BorderRadius.circular(4),
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
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildErrorState(DishSearchProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 40, color: AppTheme.primary),
            const SizedBox(height: 12),
            const Text(
              'Chưa tải được danh sách món ăn',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              provider.errorMessage ?? 'Vui lòng kiểm tra lại kết nối mạng',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () => provider.search(provider.query),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
