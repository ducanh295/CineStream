import 'package:flutter_test/flutter_test.dart';

import 'package:vietflix_mobile/main.dart';

void main() {
  testWidgets('VietFlix app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const VietFlixApp());

    expect(find.text('VietFlix'), findsOneWidget);
    expect(find.text('Tối nay xem gì?'), findsOneWidget);
  });
}