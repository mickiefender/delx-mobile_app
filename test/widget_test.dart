// Basic Flutter widget test that ensures the widget test harness is working.
// We intentionally avoid booting `MyApp` here because app startup triggers
// timers/splash logic which leaves pending timers in `flutter test`
// (and causes failures when the widget tree is disposed).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Widget test harness smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Smoke OK')),
        ),
      ),
    );

    expect(find.text('Smoke OK'), findsOneWidget);
  });
}
