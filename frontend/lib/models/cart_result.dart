class CartSummary {
  final int total;
  final int available;
  final int unavailable;
  final int estimatedTotalVnd;

  CartSummary({
    required this.total,
    required this.available,
    required this.unavailable,
    required this.estimatedTotalVnd,
  });

  factory CartSummary.fromJson(Map<String, dynamic> json) {
    return CartSummary(
      total: (json['total'] as num).toInt(),
      available: (json['available'] as num).toInt(),
      unavailable: (json['unavailable'] as num).toInt(),
      estimatedTotalVnd: (json['estimated_total_vnd'] as num).toInt(),
    );
  }
}

class CartItem {
  final String ingredient;
  final String normalizedName;
  final double quantity;
  final String unit;
  final bool available;
  final String? sku;
  final String? productName;
  final double? packSize;
  final int? packsNeeded;
  final int? priceVnd;
  final int? subtotalVnd;
  final String? searchUrl;
  final String? note;

  CartItem({
    required this.ingredient,
    required this.normalizedName,
    required this.quantity,
    required this.unit,
    required this.available,
    this.sku,
    this.productName,
    this.packSize,
    this.packsNeeded,
    this.priceVnd,
    this.subtotalVnd,
    this.searchUrl,
    this.note,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      ingredient: json['ingredient'],
      normalizedName: json['normalized_name'],
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'],
      available: json['available'] as bool,
      sku: json['sku'] as String?,
      productName: json['product_name'] as String?,
      packSize: (json['pack_size'] as num?)?.toDouble(),
      packsNeeded: (json['packs_needed'] as num?)?.toInt(),
      priceVnd: (json['price_vnd'] as num?)?.toInt(),
      subtotalVnd: (json['subtotal_vnd'] as num?)?.toInt(),
      searchUrl: json['search_url'] as String?,
      note: json['note'] as String?,
    );
  }
  String get name => productName ?? ingredient;
  int get packQuantity => packsNeeded ?? 1;
  int get totalPrice => subtotalVnd ?? priceVnd ?? 0;
}

class CartResult {
  final String requestId;
  final String status;
  final CartSummary summary;
  final List<CartItem> items;
  final String? notionPageId;

  CartResult({
    required this.requestId,
    required this.status,
    required this.summary,
    required this.items,
    this.notionPageId,
  });

  int get totalEstimatedPrice => summary.estimatedTotalVnd;
  List<CartItem> get availableItems => items.where((i) => i.available).toList();
  List<CartItem> get unavailableItems => items.where((i) => !i.available).toList();

  factory CartResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return CartResult(
      requestId: data['request_id'],
      status: data['status'],
      summary: CartSummary.fromJson(data['summary']),
      items: (data['items'] as List<dynamic>)
          .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      notionPageId: data['notion_page_id'] as String?,
    );
  }
}