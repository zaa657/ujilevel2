import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';
import 'package:mobile/screens/splash_screen.dart';

void main() {
  testWidgets('Initial screen renders splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const SportBookApp());
    expect(find.byType(SplashScreen), findsOneWidget);
  });
}
