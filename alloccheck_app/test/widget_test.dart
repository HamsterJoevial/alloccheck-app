import 'package:flutter_test/flutter_test.dart';
import 'package:alloccheck_app/main.dart';

void main() {
  testWidgets('AllocCheck home screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const AllocCheckApp());

    expect(find.text('AllocCheck'), findsOneWidget);
    expect(find.text('Vérifier vos droits'), findsOneWidget);
  });
}
