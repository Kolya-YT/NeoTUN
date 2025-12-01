import 'package:flutter_test/flutter_test.dart';
import 'package:neotun/main.dart';

void main() {
  testWidgets('App starts successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const NeoTunApp());

    // Verify that the app starts
    expect(find.text('NeoTUN'), findsOneWidget);
  });
}
