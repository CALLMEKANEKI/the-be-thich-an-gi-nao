// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/wheel_option.dart';

void main() {
  test('WheelOption.fromJson parses backend payload correctly', () {
    final json = {
      'dish': {
        'id': 1,
        'name': 'Bún chả',
        'description': 'Món ăn phù hợp cho buổi tối.',
        'image_url': 'https://example.com/buncha.jpg',
        'category': 'Món Việt',
      },
      'reason': 'Vì bạn đang cảm thấy chán nản, món này dễ ăn và đủ dinh dưỡng.',
      'confidence': 0.87,
    };

    final option = WheelOption.fromJson(json);

    expect(option.dish.name, 'Bún chả');
    expect(option.reason.contains('chán nản'), isTrue);
    expect(option.confidence, 0.87);
  });
}
