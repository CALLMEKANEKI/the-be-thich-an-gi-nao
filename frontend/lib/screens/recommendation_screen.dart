import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/recommendation_provider.dart';

class RecommendationScreen extends StatelessWidget {
  const RecommendationScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thế bé thích ăn gì nào')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed:(){
                 context.read<RecommendationProvider>().fetchWheelOption('Hôm nay tôi mệt quá');
              },
              child: const Text('Spin'),
              ),
              const SizedBox(height: 20),
              Consumer<RecommendationProvider>(
                builder: (context, provider, child){
                  return switch(provider.status){
                    RecommendationStatus.idle => const Text('Press button to spin'),
                    RecommendationStatus.loading => const CircularProgressIndicator(),
                    RecommendationStatus.success => provider.selectedOption == null
                    ? const Text('Đang tiến hành chọn ')
                    : Text
                    (
                      '${provider.selectedOption!.dish.name}\n'
                      '${provider.selectedOption!.reason}\n'
                      'Độ tin cậy: ${provider.selectedOption!.confidence}'
                    ),
                    RecommendationStatus.error => Text(
                      provider.errorMessage ?? 'Lỗi không xác định',
                      style: const TextStyle(color : Colors.red),
                    ) 
                  };
                },
              ),
          ],
        ),
      )
    );
  }
}