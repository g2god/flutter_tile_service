import 'package:flutter_test/flutter_test.dart';
import 'package:example/main.dart';

void main() {
  testWidgets('App renders showcase UI correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const TileDemoApp());
    expect(find.byType(TileDemoApp), findsOneWidget);
  });
}
