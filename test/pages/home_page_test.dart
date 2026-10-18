import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simorgh/core/theme.dart';
import 'package:simorgh/core/connection/connection_session.dart';
import 'package:simorgh/core/scanner/ip_scanner.dart';
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

  testWidgets('production Home starts without fabricated telemetry', (
    tester,
  ) async {
    final session = _FakeConnectionSession();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: Directionality(
            textDirection: TextDirection.ltr,
            child: HomePage(
              strings: AppStrings(const Locale('en')),
              connectionSession: session,
            ),
          ),
        ),
      ),
    );

    expect(find.text('104.16.132.48'), findsNothing);
    expect(find.text('48.2 MB/s'), findsNothing);
    expect(find.byType(ChoiceChip), findsNothing);
    expect(find.text('0 / 0 tested  •  0 clean found'), findsOneWidget);

    session.emit(
      const ConnectionViewState(
        stage: ConnectionViewStage.connected,
        progress: 100,
        testedCount: 1,
        totalCount: 1,
        cleanCount: 1,
        selectedIp: '203.0.113.10',
        candidates: [
          IpProbeResult(
            ip: '203.0.113.10',
            port: 443,
            status: IpProbeStatus.clean,
            latencyMs: 42,
          ),
        ],
      ),
    );
    await tester.pump();

    expect(find.text('203.0.113.10'), findsWidgets);
    expect(find.text('42ms'), findsOneWidget);
    expect(find.text('1 / 1 tested  •  1 clean found'), findsOneWidget);
    await session.dispose();
  });
}

class _FakeConnectionSession implements ConnectionSession {
  _FakeConnectionSession()
    : _current = const ConnectionViewState(stage: ConnectionViewStage.idle);

  final StreamController<ConnectionViewState> _controller =
      StreamController<ConnectionViewState>.broadcast();
  ConnectionViewState _current;

  @override
  ConnectionViewState get current => _current;

  @override
  Stream<ConnectionViewState> get states => _controller.stream;

  void emit(ConnectionViewState state) {
    _current = state;
    _controller.add(state);
  }

  @override
  Future<void> connect() async {}

  @override
  Future<void> disconnect() async {}

  @override
  Future<void> dispose() => _controller.close();
}
