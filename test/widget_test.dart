import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fc_career_mode/main.dart';

void main() {
  testWidgets('renders the seeded career dashboard', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: FCCareerModeApp()));

    expect(find.text('FC CAREER MODE'), findsOneWidget);
    expect(find.text('FC Elite'), findsWidgets);
    expect(find.text('المباراة القادمة'), findsOneWidget);
    expect(find.text('العب المباراة'), findsOneWidget);
    expect(find.text('الانتقالات'), findsWidgets);
  });

  testWidgets('playing a fixture advances the career state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: FCCareerModeApp()));

    await tester.tap(find.text('العب المباراة'));
    await tester.pump();

    expect(find.text('المباراة القادمة'), findsOneWidget);
    expect(find.text('0-0-0'), findsNothing);
  });
}
