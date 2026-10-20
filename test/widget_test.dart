import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:simorgh/app.dart';
import 'package:simorgh/app/composition.dart';

void main() {
  testWidgets('renders the Simorgh desktop shell', (tester) async {
    await tester.pumpWidget(const SimorghApp());
    expect(find.textContaining('Simorgh'), findsOneWidget);
    expect(find.text('اتصال'), findsOneWidget);
    expect(find.text('تونل فعال'), findsOneWidget);
  });

  testWidgets('shows the branded splash while services are starting', (
    tester,
  ) async {
    final services = Completer<AppServices>();
    await tester.pumpWidget(SimorghApp(servicesFuture: services.future));

    expect(find.byKey(const ValueKey('branded-splash')), findsOneWidget);
    expect(find.text('Simorgh'), findsOneWidget);
    expect(find.text('در حال آماده‌سازی سرویس‌ها...'), findsOneWidget);
  });
}
