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
                 context.read<RecommendationProvider>().fetchRecommendation('happy');
              },
              child: const Text('Spin'),
              ),
              const SizedBox(height: 20),
              Consumer<RecommendationProvider>(
                builder: (context, provider, child){
                  return switch(provider.status){
                    RecommendationStatus.idle => const Text('Press button to spin'),
                    RecommendationStatus.loading => const CircularProgressIndicator(),
                    RecommendationStatus.success => Text(
                      '${provider.dish?.name}\n${provider.dish?.reason}\nĐộ tin cậy: ${provider.dish?.confidence}'
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