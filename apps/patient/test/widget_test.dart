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
    expect(find.text('Bamboo Dance'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('Transitions smoothly between Games and Activities tabs without errors or key duplicates',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: GameHubPage()));
    await tester.pump(const Duration(milliseconds: 100));

    // Initially on Games tab
    expect(find.text('Choose an activity'), findsOneWidget);
    expect(find.text('Bamboo Dance'), findsOneWidget);

    // Switch to Activities tab
    await tester.tap(find.text('Activities'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Karaoke'), findsOneWidget);
    expect(find.text('Folk Stories'), findsOneWidget);

    // Switch back to Games tab
    await tester.tap(find.text('Games'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Choose an activity'), findsOneWidget);
    expect(find.text('Bamboo Dance'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
