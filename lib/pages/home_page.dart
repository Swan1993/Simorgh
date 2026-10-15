import 'dart:async';

import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../core/widgets.dart';
import '../l10n/strings.dart';

enum TunnelState { idle, scanning, connecting, connected, failed }

class HomePage extends StatefulWidget {
  const HomePage({required this.strings, super.key});
  final AppStrings strings;
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TunnelState _state = TunnelState.idle;
  Timer? _timer;
  int _progress = 0;
  final _rows = <String>['104.16.132.48', '104.19.241.93', '172.67.12.18', '104.28.14.99', '162.159.36.1'];
  AppStrings get s => widget.strings;

  void _start() {
    _timer?.cancel();
    setState(() { _state = TunnelState.scanning; _progress = 0; });
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted) return;
      setState(() {
        _progress += 8;
        if (_progress >= 72 && _progress < 100) _state = TunnelState.connecting;
        if (_progress >= 100) { _state = TunnelState.connected; timer.cancel(); }
      });
    });
  }

  void _fail() { _timer?.cancel(); setState(() => _state = TunnelState.failed); }
  String get _label => switch (_state) { TunnelState.idle => s.connect, TunnelState.scanning => s.scanning, TunnelState.connecting => 'ROUTING', TunnelState.connected => s.connected, TunnelState.failed => s.failed };
  Color get _color => switch (_state) { TunnelState.connected => AppColors.green, TunnelState.failed => AppColors.red, _ => AppColors.cyan };

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Panel(child: Column(children: [
          Wrap(spacing: 6, children: [for (final state in TunnelState.values) ChoiceChip(label: Text(state.name.toUpperCase()), selected: state == _state, onSelected: (_) => setState(() => _state = state))]),
          const SizedBox(height: 20),
          InkWell(onTap: _state == TunnelState.scanning || _state == TunnelState.connecting ? null : _start, borderRadius: BorderRadius.circular(100), child: AnimatedContainer(duration: const Duration(milliseconds: 300), width: 176, height: 176, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.surfaceLow, border: Border.all(color: _color, width: 2), boxShadow: [BoxShadow(color: _color.withValues(alpha: .25), blurRadius: 32, spreadRadius: 8)]), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(_state == TunnelState.failed ? Icons.warning_rounded : Icons.shield_rounded, color: _color, size: 42), const SizedBox(height: 8), Text(_label, style: TextStyle(color: _color, fontWeight: FontWeight.w700, letterSpacing: 1.2)), Text(_state == TunnelState.connected ? 'CF-SECURE' : s.standby, style: Theme.of(context).textTheme.labelSmall)]))),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.circle, size: 9, color: _color), const SizedBox(width: 7), Text(_state == TunnelState.failed ? 'Handshake timed out' : _state == TunnelState.connected ? 'Connected to CF Edge • Frankfurt' : 'Cloudflare Edge available')]),
          const SizedBox(height: 20),
          GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 4, crossAxisSpacing: 10, childAspectRatio: 2.1, children: [StatCard(label: s.cleanIp, value: '104.16.132.48', detail: 'v4'), StatCard(label: s.latency, value: '24 ms', detail: 'Jitter 1.2ms', color: AppColors.green), StatCard(label: s.transfer, value: '48.2 MB/s', detail: '↓ 48.2  ↑ 12.4'), StatCard(label: s.totalPayload, value: '1.84 GB', detail: '/ 420 MB')]),
          const SizedBox(height: 18),
          Wrap(spacing: 10, children: [FilledButton.icon(onPressed: _start, icon: const Icon(Icons.refresh_rounded), label: Text(s.forceRescan)), OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.swap_horiz_rounded), label: const Text('Switch Relay')), OutlinedButton.icon(onPressed: _fail, icon: const Icon(Icons.bug_report_outlined), label: const Text('Force Fail'))]),
        ])),
        const SizedBox(height: 18),
        Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          PageHeader(title: s.scannerTitle, subtitle: s.scannerSubtitle, action: OutlinedButton.icon(onPressed: _state == TunnelState.scanning ? () => setState(() => _state = TunnelState.idle) : null, icon: const Icon(Icons.cancel_outlined), label: Text(s.cancel))),
          const SizedBox(height: 18),
          LinearProgressIndicator(value: _progress / 100, minHeight: 8, borderRadius: BorderRadius.circular(8)),
          const SizedBox(height: 8),
          Row(children: [Mono('$_progress%'), const Spacer(), Text('1,720 / 2,500 ${s.tested}  •  42 ${s.cleanFound}', style: Theme.of(context).textTheme.bodySmall)]),
          const SizedBox(height: 16),
          Wrap(spacing: 8, runSpacing: 8, children: [for (final item in [s.prepare, s.scanIps, s.selectBest, s.buildConfig, s.startCore, s.verify]) StatusChip(item, color: AppColors.green)]),
          const SizedBox(height: 16),
          for (var i = 0; i < _rows.length; i++) _IpRow(ip: _rows[i], latency: '${24 + i * 7}ms', clean: i < 3, best: i == 0),
        ])),
      ]));
}

class _IpRow extends StatelessWidget {
  const _IpRow({required this.ip, required this.latency, required this.clean, required this.best});
  final String ip;
  final String latency;
  final bool clean;
  final bool best;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12), decoration: BoxDecoration(color: best ? AppColors.cyan.withValues(alpha: .08) : Colors.transparent, border: const Border(bottom: BorderSide(color: AppColors.outline))), child: Row(children: [if (best) const Icon(Icons.star_rounded, size: 16, color: AppColors.amber) else const SizedBox(width: 16), const SizedBox(width: 8), Expanded(child: Mono(ip, color: best ? AppColors.cyan : null)), Mono(latency, color: AppColors.muted), const SizedBox(width: 18), StatusChip(clean ? 'CLEAN' : 'BLOCKED', color: clean ? AppColors.green : AppColors.red)]));
}
