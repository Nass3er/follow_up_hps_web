import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:follow_up_hps_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const HpsFollowUpApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
