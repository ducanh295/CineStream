import 'package:flutter_test/flutter_test.dart';

import 'package:cinestream_mobile/main.dart';

void main() {
  testWidgets('CineStream app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const CineStreamApp());

    expect(find.text('CineStream'), findsOneWidget);
    expect(find.text('Trải nghiệm điện ảnh đỉnh cao'), findsOneWidget);
  });
}