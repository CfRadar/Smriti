import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('GameHubPage renders cleanly on narrow 320px mobile screens without overflow',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const MaterialApp(home: GameHubPage()));
    await tester.pump();

    expect(find.text('Smriti'), findsOneWidget);
    expect(find.text('Choose an activity'), findsOneWidget);
    expect(find.text('Blink Memory'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });
}
