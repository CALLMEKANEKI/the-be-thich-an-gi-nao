import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/app_theme.dart';
import 'provider/auth_provider.dart';
import 'provider/cart_provider.dart';
import 'provider/dish_search_provider.dart';
import 'provider/ingredient_provider.dart';
import 'provider/places_provider.dart';
import 'provider/recommendation_provider.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RecommendationProvider()),
        ChangeNotifierProvider(create: (_) => PlacesProvider()),
        ChangeNotifierProvider(create: (_) => IngredientProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => DishSearchProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const FoodPickerApp(),
    ),
  );
}

class FoodPickerApp extends StatelessWidget {
  const FoodPickerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Thế bé thích ăn gì nào?',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
    );
  }
}
