import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ingredient.dart';
import '../provider/cart_provider.dart';

class CartTestScreen extends StatelessWidget {
  const CartTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cart test')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              context.read<CartProvider>().createCart(
                dishId: 1,
                dishName: 'Cà chua xào trứng',
                ingredients: [
                  Ingredient(name: 'Cà chua', normalizedName: 'ca_chua', quantity: 2, unit: 'quả'),
                  Ingredient(name: 'Trứng gà', normalizedName: 'trung_ga', quantity: 3, unit: 'quả'),
                  Ingredient(name: 'Lá gai', normalizedName: 'la_gai', quantity: 50, unit: 'g'),
                ],
              );
            },
            child: const Text('Tạo giỏ hàng'),
          ),
          Expanded(
            child: Consumer<CartProvider>(
              builder: (context, p, child) {
                return switch (p.status) {
                  CartStatus.idle => const Center(child: Text('Bấm nút để tạo giỏ')),
                  CartStatus.loading => const Center(child: CircularProgressIndicator()),
                  CartStatus.error => Center(
                      child: Text(p.errorMessage ?? 'Lỗi', style: const TextStyle(color: Colors.red)),
                    ),
                  CartStatus.success => ListView(
                      children: [
                        if (p.isFromCache)
                          const ListTile(
                            title: Text('Dữ liệu cũ (offline)', style: TextStyle(color: Colors.orange)),
                          ),
                        ListTile(
                          title: Text('Có thể mua: ${p.cart!.summary.available} | Tự mua: ${p.cart!.summary.unavailable}'),
                          subtitle: Text('Ước tính: ${p.cart!.summary.estimatedTotalVnd}đ'),
                        ),
                        for (final i in p.cart!.items)
                          ListTile(
                            title: Text('${i.ingredient} (${i.quantity} ${i.unit})'),
                            subtitle: Text(i.available
                                ? '${i.packsNeeded} × ${i.productName} = ${i.subtotalVnd}đ'
                                : (i.note ?? 'Tự mua')),
                          ),
                      ],
                    ),
                };
              },
            ),
          ),
        ],
      ),
    );
  }
}