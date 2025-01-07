import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ble_app/ble_scan_screen.dart';

void main() {
  testWidgets('BLEScanScreen UI smoke test', (WidgetTester tester) async {
    // Build the BLEScanScreen widget.
    await tester.pumpWidget(const MaterialApp(home: BLEScanScreen()));

    // Verify the app bar title.
    expect(find.text('BLE Device Scanner'), findsOneWidget);

    // Verify the initial state: scanning should not be active.
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('No devices found.'), findsOneWidget);

    // Simulate pressing the refresh button.
    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pump();

    // Verify that a CircularProgressIndicator is displayed when scanning.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
