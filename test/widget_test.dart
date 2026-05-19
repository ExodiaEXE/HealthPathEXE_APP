import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health/main.dart';

void main() {
  testWidgets('HealthPath shows login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const HealthPathApp());
    await tester.pump();

    expect(find.text('HealthPath'), findsOneWidget);
    expect(find.text('Dang nhap'), findsWidgets);
  });
}
