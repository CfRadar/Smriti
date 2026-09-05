import 'package:flutter_test/flutter_test.dart';
import 'package:patient/main.dart';

void main() {
  testWidgets('Patient app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SmritiPatientApp());
    expect(find.text('Smriti (स्मृति)'), findsOneWidget);
  });
}
