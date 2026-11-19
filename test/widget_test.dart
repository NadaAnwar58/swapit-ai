import 'package:flutter_test/flutter_test.dart';

import 'package:swapit/main.dart';

void main() {
  testWidgets('Welcome screen shows app name and tagline', (WidgetTester tester) async {
    // شغّل التطبيق
    await tester.pumpWidget(const SwapitApp());

    // تأكد إن اسم التطبيق والجملة ظاهرين
    expect(find.text('Swapit AI'), findsOneWidget);
    expect(find.text('بدّل اللي مش محتاجه بحاجة إنت محتاجها.'), findsOneWidget);

    // تأكد إن العداد القديم اتشال
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsNothing);
  });
}