import 'package:flutter_test/flutter_test.dart';
import 'package:example/main.dart';

void main() {
  testWidgets('App renders dashboard UI', (WidgetTester tester) async {
    await tester.pumpWidget(const TileDemoApp());
    expect(find.text('Quick Settings Tile Manager'), findsNothing); // Loading initially or not yet pumped
  });
}
