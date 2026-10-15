import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'l10n/strings.dart';
import 'pages/ai_settings_page.dart';
import 'pages/console_page.dart';
import 'pages/home_page.dart';
import 'pages/relays_page.dart';
import 'pages/settings_page.dart';

class SimorghApp extends StatefulWidget {
  const SimorghApp({super.key});
  @override
  State<SimorghApp> createState() => _SimorghAppState();
}

class _SimorghAppState extends State<SimorghApp> {
  Locale _locale = const Locale('fa');
  void _setLocale(Locale locale) => setState(() => _locale = locale);

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings(_locale);
    return MaterialApp(debugShowCheckedModeBanner: false, title: strings.appName, theme: AppTheme.dark, locale: _locale, home: AppShell(strings: strings, onLocaleChanged: _setLocale));
  }
}

class AppShell extends StatefulWidget {
  const AppShell({required this.strings, required this.onLocaleChanged, super.key});
  final AppStrings strings;
  final ValueChanged<Locale> onLocaleChanged;
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final pages = <Widget>[HomePage(strings: s), RelaysPage(strings: s), ConsolePage(strings: s), AiSettingsPage(strings: s), SettingsPage(strings: s, onLocaleChanged: widget.onLocaleChanged)];
    final labels = [s.home, s.relays, s.console, s.aiSettings, s.settings];
    final icons = [Icons.home_rounded, Icons.hub_rounded, Icons.terminal_rounded, Icons.auto_awesome_rounded, Icons.settings_rounded];
    return Directionality(
      textDirection: s.direction,
      child: Scaffold(
        body: SafeArea(
          child: Column(children: [
            _TitleBar(strings: s),
            Expanded(child: Row(textDirection: s.direction, children: [
              NavigationRail(selectedIndex: _selectedIndex, onDestinationSelected: (index) => setState(() => _selectedIndex = index), labelType: NavigationRailLabelType.all, groupAlignment: -0.85, destinations: [for (var i = 0; i < labels.length; i++) NavigationRailDestination(icon: Icon(icons[i]), label: Text(labels[i]))]),
              const VerticalDivider(width: 1),
              Expanded(child: IndexedStack(index: _selectedIndex, children: pages)),
            ])),
            _StatusFooter(strings: s),
          ]),
        ),
      ),
    );
  }
}

class _TitleBar extends StatelessWidget {
  const _TitleBar({required this.strings});
  final AppStrings strings;
  @override
  Widget build(BuildContext context) => Container(height: 48, padding: const EdgeInsets.symmetric(horizontal: 18), decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.outline))), child: Row(children: [const Icon(Icons.flight_takeoff_rounded, color: AppColors.cyan), const SizedBox(width: 10), Text('${strings.appName} • v0.1.0', style: Theme.of(context).textTheme.titleSmall), const Spacer(), const Icon(Icons.circle, size: 8, color: AppColors.green), const SizedBox(width: 6), Text(strings.edgeSynced, style: Theme.of(context).textTheme.labelSmall)]));
}

class _StatusFooter extends StatelessWidget {
  const _StatusFooter({required this.strings});
  final AppStrings strings;
  @override
  Widget build(BuildContext context) => Container(height: 34, padding: const EdgeInsets.symmetric(horizontal: 18), decoration: const BoxDecoration(color: AppColors.surfaceLow, border: Border(top: BorderSide(color: AppColors.outline))), child: Row(children: [const Icon(Icons.shield_rounded, size: 14, color: AppColors.green), const SizedBox(width: 8), Text(strings.activeTunnel), const SizedBox(width: 8), Text(strings.online, style: const TextStyle(color: AppColors.green)), const Spacer(), Text('28ms  •  ${strings.ready}', style: const TextStyle(fontFamily: 'monospace', color: AppColors.muted))]));
}
