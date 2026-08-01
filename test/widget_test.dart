import 'package:flutter_test/flutter_test.dart';

import 'package:pgm_app/main.dart';

void main() {
  testWidgets('App boots to login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const PgmApp());
    expect(find.text('PG Manager'), findsOneWidget);
  });
}
