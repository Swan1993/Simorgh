import 'dart:async';

import 'package:flutter/material.dart';

import 'app/composition.dart';
import 'core/connection/connection_session.dart';
import 'core/theme.dart';
import 'l10n/strings.dart';
import 'pages/ai_settings_page.dart';
import 'pages/console_page.dart';
import 'pages/home_page.dart';
import 'pages/relays_page.dart';
import 'pages/settings_page.dart';

class SimorghApp extends StatefulWidget {
  const SimorghApp({this.services, super.key});
  final AppServices? services;
  @override
  State<SimorghApp> createState() => _SimorghAppState();
}

class _SimorghAppState extends State<SimorghApp> {
  Locale _locale = const Locale('fa');
  void _setLocale(Locale locale) => setState(() => _locale = locale);

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings(_locale);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: strings.appName,
      theme: AppTheme.dark,
      locale: _locale,
      home: AppShell(
        strings: strings,
        onLocaleChanged: _setLocale,
        services: widget.services,
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({
    required this.strings,
    required this.onLocaleChanged,
    this.services,
    super.key,
  });
  final AppStrings strings;
  final ValueChanged<Locale> onLocaleChanged;
  final AppServices? services;
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  ConnectionViewState _connectionState = const ConnectionViewState(
    stage: ConnectionViewStage.idle,
  );
  StreamSubscription<ConnectionViewState>? _connectionSubscription;

  @override
  void initState() {
    super.initState();
    _subscribeToConnection();
  }

  @override
  void didUpdateWidget(covariant AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.services?.connection != widget.services?.connection) {
      _subscribeToConnection();
    }
  }

  void _subscribeToConnection() {
    final connection = widget.services?.connection;
    _connectionSubscription?.cancel();
    _connectionState =
        connection?.current ??
        const ConnectionViewState(stage: ConnectionViewStage.idle);
    if (connection == null) {
      return;
    }
    _connectionSubscription = connection.states.listen((state) {
      if (!mounted || connection != widget.services?.connection) return;
      setState(() => _connectionState = state);
    });
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final pages = <Widget>[
      HomePage(strings: s, connectionSession: widget.services?.connection),
      RelaysPage(strings: s, repository: widget.services?.relays),
      ConsolePage(strings: s, logger: widget.services?.logger),
      AiSettingsPage(strings: s, secrets: widget.services?.secrets),
      SettingsPage(strings: s, onLocaleChanged: widget.onLocaleChanged),
    ];
    final labels = [s.home, s.relays, s.console, s.aiSettings, s.settings];
    final icons = [
      Icons.home_rounded,
      Icons.hub_rounded,
      Icons.terminal_rounded,
      Icons.auto_awesome_rounded,
      Icons.settings_rounded,
    ];
    return Directionality(
      textDirection: s.direction,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _TitleBar(
                strings: s,
                status: _shellConnectionStatus(_connectionState),
                preview: widget.services == null,
              ),
              Expanded(
                child: Row(
                  textDirection: s.direction,
                  children: [
                    NavigationRail(
                      selectedIndex: _selectedIndex,
                      onDestinationSelected: (index) =>
                          setState(() => _selectedIndex = index),
                      labelType: NavigationRailLabelType.all,
                      groupAlignment: -0.85,
                      destinations: [
                        for (var i = 0; i < labels.length; i++)
                          NavigationRailDestination(
                            icon: Icon(icons[i]),
                            label: Text(labels[i]),
                          ),
                      ],
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(
                      child: IndexedStack(
                        index: _selectedIndex,
                        children: pages,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusFooter(
                strings: s,
                state: _connectionState,
                status: _shellConnectionStatus(_connectionState),
                preview: widget.services == null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TitleBar extends StatelessWidget {
  const _TitleBar({
    required this.strings,
    required this.status,
    required this.preview,
  });
  final AppStrings strings;
  final _ShellConnectionStatus status;
  final bool preview;

  @override
  Widget build(BuildContext context) {
    final presentation = _connectionPresentation(strings, status);
    final statusLabel = preview ? strings.edgeSynced : presentation.label;
    final statusColor = preview ? AppColors.green : presentation.color;
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.outline)),
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/logo/logo.png',
            width: 24,
            height: 24,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.auto_awesome, color: AppColors.cyan),
          ),
          const SizedBox(width: 10),
          Text(
            '${strings.appName} • v0.1.0',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const Spacer(),
          Icon(Icons.circle, size: 8, color: statusColor),
          const SizedBox(width: 6),
          Text(
            statusLabel,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: statusColor),
          ),
        ],
      ),
    );
  }
}

class _StatusFooter extends StatelessWidget {
  const _StatusFooter({
    required this.strings,
    required this.state,
    required this.status,
    required this.preview,
  });
  final AppStrings strings;
  final ConnectionViewState state;
  final _ShellConnectionStatus status;
  final bool preview;

  @override
  Widget build(BuildContext context) {
    if (preview) {
      return Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: const BoxDecoration(
          color: AppColors.surfaceLow,
          border: Border(top: BorderSide(color: AppColors.outline)),
        ),
        child: Row(
          children: [
            const Icon(Icons.shield_rounded, size: 14, color: AppColors.green),
            const SizedBox(width: 8),
            Text(strings.activeTunnel),
            const SizedBox(width: 8),
            Text(
              strings.online,
              style: const TextStyle(color: AppColors.green),
            ),
            const Spacer(),
            Text(
              '28ms  •  ${strings.ready}',
              style: const TextStyle(
                fontFamily: 'monospace',
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      );
    }

    final presentation = _connectionPresentation(strings, status);
    final detail = status == _ShellConnectionStatus.connected
        ? '${_connectedLatency(state) ?? '—'}  •  ${strings.ready}'
        : '—  •  ${presentation.label}';
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: const BoxDecoration(
        color: AppColors.surfaceLow,
        border: Border(top: BorderSide(color: AppColors.outline)),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_rounded, size: 14, color: presentation.color),
          const SizedBox(width: 8),
          Text(presentation.label),
          const SizedBox(width: 8),
          Text(
            status == _ShellConnectionStatus.connected
                ? strings.online
                : _offlineLabel(strings),
            style: TextStyle(color: presentation.color),
          ),
          const Spacer(),
          Text(
            detail,
            style: const TextStyle(
              fontFamily: 'monospace',
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

enum _ShellConnectionStatus { idle, scanning, connecting, connected, failed }

class _ConnectionPresentation {
  const _ConnectionPresentation({required this.label, required this.color});

  final String label;
  final Color color;
}

_ShellConnectionStatus _shellConnectionStatus(ConnectionViewState state) =>
    switch (state.stage) {
      ConnectionViewStage.idle => _ShellConnectionStatus.idle,
      ConnectionViewStage.scanning => _ShellConnectionStatus.scanning,
      ConnectionViewStage.preparing ||
      ConnectionViewStage.selectingBest ||
      ConnectionViewStage.buildingConfig ||
      ConnectionViewStage.startingCore ||
      ConnectionViewStage.verifyingConnection =>
        _ShellConnectionStatus.connecting,
      ConnectionViewStage.connected => _ShellConnectionStatus.connected,
      ConnectionViewStage.failed => _ShellConnectionStatus.failed,
    };

_ConnectionPresentation _connectionPresentation(
  AppStrings strings,
  _ShellConnectionStatus status,
) => switch (status) {
  _ShellConnectionStatus.idle => _ConnectionPresentation(
    label: _idleLabel(strings),
    color: AppColors.muted,
  ),
  _ShellConnectionStatus.scanning => _ConnectionPresentation(
    label: strings.scanning,
    color: AppColors.cyan,
  ),
  _ShellConnectionStatus.connecting => _ConnectionPresentation(
    label: _connectingLabel(strings),
    color: AppColors.amber,
  ),
  _ShellConnectionStatus.connected => _ConnectionPresentation(
    label: strings.edgeSynced,
    color: AppColors.green,
  ),
  _ShellConnectionStatus.failed => _ConnectionPresentation(
    label: strings.failed,
    color: AppColors.red,
  ),
};

String _idleLabel(AppStrings strings) => strings.isFa
    ? 'آماده اتصال'
    : strings.isHi
    ? 'स्टैंडबाय'
    : 'IDLE';

String _connectingLabel(AppStrings strings) => strings.isFa
    ? 'در حال اتصال'
    : strings.isHi
    ? 'कनेक्ट हो रहा है'
    : 'CONNECTING';

String _offlineLabel(AppStrings strings) => strings.isFa
    ? 'آفلاین'
    : strings.isHi
    ? 'ऑफ़लाइन'
    : 'OFFLINE';

int? _connectedLatency(ConnectionViewState state) {
  final selectedIp = state.selectedIp;
  if (selectedIp == null) return null;
  for (final candidate in state.candidates) {
    if (candidate.ip == selectedIp) return candidate.latencyMs;
  }
  return null;
}
