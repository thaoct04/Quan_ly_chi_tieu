import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ocr_expense_tracker/main.dart';

void main() {
  testWidgets('OCR Expense Tracker smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: OcrExpenseApp()));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
