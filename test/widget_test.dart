import 'package:flutter_test/flutter_test.dart';
import 'package:health/core/config/env_config.dart';
import 'package:health/main.dart';

void main() {
  testWidgets('HealthPath shows login screen', (WidgetTester tester) async {
    EnvConfig.loadForTest();
    await tester.pumpWidget(const HealthPathApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('HealthPath'), findsOneWidget);
    expect(find.text('Đăng nhập'), findsWidgets);
  });
}
