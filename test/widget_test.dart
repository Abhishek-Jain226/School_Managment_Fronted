
import 'package:flutter_test/flutter_test.dart';
import 'package:school_tracker/app.dart'; // Make sure this points to your app.dart

void main() {
  testWidgets('Splash screen loads correctly', (WidgetTester tester) async {
    // Build the app and trigger a frame.
    await tester.pumpWidget(const App());

    // Verify that splash screen text appears (change the text if needed)
    expect(find.text('School Tracking App'), findsOneWidget);
  });
}
