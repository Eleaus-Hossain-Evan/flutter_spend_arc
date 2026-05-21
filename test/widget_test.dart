import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_spend_arc/main.dart';

void main() {
  testWidgets('SpendArc app renders', (WidgetTester tester) async {
    await tester.pumpWidget(const SpendArcApp());
    expect(find.text('SpendArc'), findsOneWidget);
  });
}
