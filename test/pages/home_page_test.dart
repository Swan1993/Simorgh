import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simorgh/core/theme.dart';
import 'package:simorgh/l10n/strings.dart';
import 'package:simorgh/pages/home_page.dart';

void main() {
  Widget buildPage() => MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: HomePage(strings: AppStrings(const Locale('fa'))),
      ),
    ),
  );

  testWidgets('cancel stops an in-progress connection and resets progress', (
    tester,
  ) async {
    await tester.pumpWidget(buildPage());
    await tester.tap(find.byKey(const ValueKey<String>('connect-orb')));
    await tester.pump(const Duration(milliseconds: 4500));

    final cancelButton = find.byKey(const ValueKey<String>('cancel-scan'));
    expect(cancelButton, findsOneWidget);
    await tester.ensureVisible(cancelButton);
    await tester.tap(cancelButton);
    await tester.pump();
    expect(find.text('0%'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('0%'), findsOneWidget);
  });

  testWidgets('the connected orb disconnects instead of starting a new scan', (
    tester,
  ) async {
    await tester.pumpWidget(buildPage());
    await tester.tap(find.byKey(const ValueKey<String>('connect-orb')));
    await tester.pump(const Duration(seconds: 7));

    await tester.tap(find.byKey(const ValueKey<String>('connect-orb')));
    await tester.pump();
    expect(find.text('0%'), findsOneWidget);
  });
}
