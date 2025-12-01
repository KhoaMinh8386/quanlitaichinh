import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:financial_management/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FinancialManagementApp());

    expect(find.text('Financial Management'), findsOneWidget);
    expect(find.text('Welcome to Financial Management'), findsOneWidget);
  });
}
