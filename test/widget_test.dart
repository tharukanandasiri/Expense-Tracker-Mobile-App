// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:expense_tracker_mobile_app/main.dart';

void main() {
  testWidgets('shows the empty expense dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.byType(RichText), findsWidgets);
    expect(find.text('Total spent'), findsOneWidget);
    expect(find.text('No expenses yet'), findsOneWidget);
    expect(find.text('Add expense'), findsOneWidget);
  });

  testWidgets('renders without overflow on a narrow viewport', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(960, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.byType(RichText), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
