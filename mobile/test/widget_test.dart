import 'package:flutter_test/flutter_test.dart';

import 'package:fasotransport_mobile/main.dart';

void main() {
  testWidgets('shows role selector on startup', (WidgetTester tester) async {
    await tester.pumpWidget(const FasoTransportApp());

    expect(find.text('Choisissez un profil'), findsOneWidget);
    expect(find.text('Passager'), findsOneWidget);
    expect(find.text('Agent terrain'), findsOneWidget);
  });
}
